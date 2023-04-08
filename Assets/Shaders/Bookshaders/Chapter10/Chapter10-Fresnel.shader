Shader "ShaderBook/Chapter10/Chapter10-Fresnel"
{
    //注:这个shader的fresnel项(被反射的光和入射光之间的比例关系)计算出来之后,进行lerp插值的是反射光和diffuse
    //不包含折射项,包含折射项的详见水波效果
    Properties
    {
        _Color("Color Tint", Color) = (1,1,1,1)
        _FresnelScale("Fresnel Scale",Range(0,1)) = 0.5
        _Cubemap("Reflection Cubemap", Cube)="_Skybox" {}
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
         
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldRefl: TEXCOORD2;
                float3 worldViewDir : TEXCOORD3; //新增要计算worldViewDir,计算fresnel项的时候需要
                SHADOW_COORDS(4)
            };

            fixed4 _Color;
            float _FresnelScale;
            samplerCUBE _Cubemap;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
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
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb;
                //使用Schilick菲涅耳近似等式
                //_FresnelScale为1,完全反射cubemap;_FresnelScale为0,具有边缘光照效果的漫反射
                fixed fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1-dot(worldViewDir,worldNormal),5);
                
                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));
                fixed3 color = ambient + atten * lerp(diffuse, reflection, saturate(fresnel));
                return fixed4(color, 1.0);
            }
            ENDCG
        }
    }
}
