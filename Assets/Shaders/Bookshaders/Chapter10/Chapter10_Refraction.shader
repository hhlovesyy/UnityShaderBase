Shader "ShaderBook/Chapter10/Chapter10_Refraction"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _RefractColor("Refraction Color", Color)=(1,1,1,1)
        _RefractAmount("Refract Amount", Range(0,1))=1
        _RefractRatio("Refract Ratio", Range(0.1,1))=0.5  //不同介质的透射比
        _Cubemap("Refraction Cubemap", Cube) = "_Skybox"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags {"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            #pragma multi_compile_fwdbase

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldRefr : TEXCOORD2;
                SHADOW_COORDS(3)
            };
            
            fixed4 _Color;
            fixed4 _RefractColor;
            float _RefractAmount;
            float _RefractRatio;
            samplerCUBE _Cubemap;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldViewDir = UnityWorldSpaceViewDir(o.worldPos);

                //Compute the refract dir in world space
                //第一个参数:入射光线的方向,必须归一化
                //第二个参数:表面法线,同样必须归一化
                //第三个参数:入射光线所在介质折射率和折射光线所在介质的折射率之间的比值
                o.worldRefr = refract(-normalize(worldViewDir), normalize(o.worldNormal), _RefractRatio);

                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize((UnityWorldSpaceLightDir(i.worldPos)));
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

                //Use the refract dir in the world space to access the cubemap
                fixed3 refraction = texCUBE(_Cubemap, i.worldRefr).rgb * _RefractColor.rgb;
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                fixed3 color = ambient + atten * lerp(diffuse, refraction, _RefractAmount);
                return fixed4(color, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Reflective/VertexLit"
}
