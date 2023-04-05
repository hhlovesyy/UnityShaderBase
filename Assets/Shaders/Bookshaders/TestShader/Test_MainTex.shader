Shader "ShaderBook/Test/Test_MainTex"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Gloss("Gloss", Range(8.0,256)) = 20
        _Color("Color Tint", Color)=(1,1,1,1)
        _Specular("Specular", Color)=(1,1,1,1) 
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
                float3 normal: NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                fixed3 worldNormal: TEXCOORD1;
                float3 worldPos:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Gloss;
            fixed4 _Color;
            fixed4 _Specular;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos=mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir+worldViewDir);
                
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(i.worldNormal, worldLightDir));
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(halfDir, i.worldNormal)), _Gloss);
                fixed3 ambient = albedo * UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                return fixed4(ambient+diffuse+specular, 1.0);
            }
            ENDCG
        }
    }
}
