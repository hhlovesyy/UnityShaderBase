Shader "ShaderBook/Test/Test_BumpTex_TangentSpace"
{
    Properties
    {
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _BumpTex("BumpTex", 2D) = "bump" {}
        _BumpScale("BumpScale",Float) = 1.0
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

            fixed4 _Specular;
            float _Gloss;
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _BumpScale;
            sampler2D _BumpTex;
            float4 _BumpTex_ST;
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal: NORMAL;
                float4 tangent: TANGENT;
                float4 texcoord:TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 tangentLightDir: TEXCOORD0;
                float4 uv:TEXCOORD1;
                float3 tangentViewDir : TEXCOORD2;
            };
            

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex); 
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpTex);

                TANGENT_SPACE_ROTATION;

                o.tangentLightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
                o.tangentViewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                fixed3 tangentLightDir = normalize(i.tangentLightDir);
                fixed3 tangentViewDir = normalize(i.tangentViewDir);  
                fixed3 tangentHalfDir = normalize(tangentLightDir+tangentViewDir);
                fixed3 albedo = tex2D(_MainTex,i.uv.xy).rgb*_Color.rgb;

                fixed3 normal = UnpackNormal(tex2D(_BumpTex,i.uv.zw));
                normal.xy *= _BumpScale;
                normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));

                fixed3 diffuse = _LightColor0.rgb*albedo*max(0,dot(tangentLightDir,normal));
                fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0,dot(tangentHalfDir,normal)),_Gloss);

                
                //fixed3 halfLambert = dot(worldLightDir,i.worldNormal);
                

                //half-lambert
                //fixed3 diffuse = _LightColor0.rgb*albedo*halfLambert;
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*albedo; //如果不乘albedo,则可以想象没有光照的地方应该是黑色的,而不会有纹理,不符合条件

                //half-lambert open this
                //fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 color = ambient+specular+diffuse;
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
    Fallback "Specular"
}
