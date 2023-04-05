Shader "ShaderBook/Chapter9/Chapter9-AttenuationAndShadowUseBuiltinFunc"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Float) = 8.0
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
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL; 
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Specular;
            float _Gloss;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                // Pass shadow coordinates to pixel shader
			 	TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 albedo = tex2D(_MainTex, i.uv);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir+worldViewDir);

                fixed3 diffuse = albedo * _LightColor0.rgb * max(0, dot(worldNormal, worldLightDir));
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * pow(max(dot(worldNormal, halfDir),0), _Gloss);
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                // UNITY_LIGHT_ATTENUATION not only compute attenuation, but also shadow infos
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                
                return fixed4(ambient + atten*(diffuse+specular),1.0);
            }
            ENDCG
        }
        
        Pass
        {
            Tags {"LightMode"="ForwardAdd"}
            Blend One One
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd
            // Use the line below to add shadows for point and spot lights(似乎开启之后只有点光源的话,还是无法收到别的物体投射过来的阴影,后面有时间再看看)
            //#pragma multi_compile_fwdadd_fullshadows

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL; 
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Specular;
            float _Gloss;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                // Pass shadow coordinates to pixel shader
			 	TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 albedo = tex2D(_MainTex, i.uv);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir+worldViewDir);

                fixed3 diffuse = albedo * _LightColor0.rgb * max(0, dot(worldNormal, worldLightDir));
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * pow(max(dot(worldNormal, halfDir),0), _Gloss);
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                // UNITY_LIGHT_ATTENUATION not only compute attenuation, but also shadow infos
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                
                return fixed4(ambient + atten*(diffuse+specular),1.0);
            }
            ENDCG
        }
    }
    Fallback "Specular"
}
