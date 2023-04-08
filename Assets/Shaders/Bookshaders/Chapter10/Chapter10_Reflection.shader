Shader "ShaderBook/Chapter10/Chapter10_Reflection"
{
    Properties
    {
        _Color("Color Tint", Color)=(1,1,1,1)
        _ReflectColor("Reflection Color",Color)=(1,1,1,1)  //用于控制反射颜色
        _ReflectAmount("Reflect Amount", Range(0,1))=1 //用于控制这个材质的反射程度
        _Cubemap ("Reflection Cubemap", Cube)="_Skybox" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}

        Pass
        {
            Tags {"LightMode"="ForwardBase"} //这句别忘了,不然光照结果会呈现黑色,有问题
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            fixed4 _ReflectColor;
            float _ReflectAmount;
            samplerCUBE _Cubemap; //注意Cubemap的类型
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal: TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                float3 worldRefl : TEXCOORD3;
                SHADOW_COORDS(4)
            };
            

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                //在本shader当中,是为了找到哪条光线反射到了摄像机里,但是由于光路可逆,因此可以由-o.worldViewDir得到
                o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);  

                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize((UnityWorldSpaceLightDir(i.worldPos)));
                fixed3 worldViewDir = normalize(i.worldViewDir);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

                //Use the reflect dir in world space to access the cubemap
                //i.worldRefl不需要归一化,因为我们需要的是个方向即可
                fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb * _ReflectColor.rgb;

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                //Mix the diffuse color with the reflected color
                fixed3 color = ambient + atten * lerp(diffuse, reflection, _ReflectAmount);
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
    FallBack "Reflective/VertexLit"
}
