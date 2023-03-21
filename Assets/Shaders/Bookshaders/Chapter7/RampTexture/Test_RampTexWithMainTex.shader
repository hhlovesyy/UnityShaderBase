Shader "ShaderBook/Chapter7/TestRampTextureWithBaseTexture"
{
    //非<入门精要>中提到的Shader,自己尝试把Ramp Texture和Base Texture结合在一起,效果是有的但是不确定代码正确性
    Properties
    {
        _Color("Color Tint", Color) = (1,1,1,1)
        _RampTex("Ramp Tex", 2D) = "white" {}
        _MainTex("Main Tex", 2D) = "white" {}
        _Specular("Specular", Color)=(1,1,1,1)
        _Gloss("Gloss", Range(8.0,256)) = 20
    }
    SubShader
    {
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _RampTex;
            float4 _RampTex_ST;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 worldPos: TEXCOORD0;
                fixed3 worldNormal: TEXCOORD1;
                float2 uv: TEXCOORD2;
            };
            
            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //lambert+blinn-phong
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 worldHalfDir = normalize(worldViewDir+worldLightDir);
                
                fixed halfLambert = 0.5 * dot(worldLightDir, i.worldNormal) + 0.5;
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                // 核心:采样Ramp Texture,用half-lambert计算出的结果采样ramp texture
                fixed3 diffuseColor = tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb;
                fixed3 diffuse =  _LightColor0.rgb * albedo * diffuseColor;
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * pow(max(0,dot(worldHalfDir, i.worldNormal)),_Gloss);
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                return fixed4(ambient + diffuse + specular, 1.0);
                
            }
            ENDCG
        }
    }
    Fallback "Specular"
}
