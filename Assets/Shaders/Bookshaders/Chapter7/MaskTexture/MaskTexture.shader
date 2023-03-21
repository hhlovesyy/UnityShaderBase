Shader "ShaderBook/Chapter7/MaskTexture"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _BumpTex ("Bump Texture", 2D) = "bump"{}
        _Gloss("Gloss", Range(8.0,256)) = 20
        _Color("Color", Color) = (1,1,1,1)
        _Specular("Specular", Color)=(1,1,1,1)
        _BumpScale("BumpScale", Float) = 1.0
        _SpecularMask("Specular mask", 2D) = "white"{}
        _SpecularScale("Specular scale", Float) = 1.0
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

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 tangent: TANGENT;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 lightDir:TEXCOORD1;
                float3 viewDir:TEXCOORD2;
            };

            fixed4 _Specular;
            float _Gloss;
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpTex;
            float _BumpScale;
            float _SpecularScale;
            sampler2D _SpecularMask;  //这里只TRANFORM_TEX一套纹理的话,剩下的可以不写_ST

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //在这里做遮罩,切线空间
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpTex, i.uv));
                
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                fixed3 diffuse = albedo * _LightColor0.rgb * max(0, dot(tangentNormal, tangentLightDir));
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 tangentHalfDir = normalize(tangentLightDir+tangentViewDir);

                //mask
                fixed specularMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;  //正常的游戏开发中,R,G,B三个通道通常用来存储不同的内容
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, tangentHalfDir)), _Gloss) * specularMask;

                return fixed4(diffuse + ambient + specular, 1.0);
                
            }
            ENDCG
        }
    }
    Fallback "Specular"
}
