Shader "ShaderBook/Chapter7/SingleTexture"
{
    //Blinn-Phong model+ simple texture
    Properties
    {
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
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
            float4 _MainTex_ST;  //需要用_ST的方式声明某个纹理的属性,ST表示scale&translation
            //.ST的xy存储缩放值,zw存储偏移值
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal: NORMAL;
                float4 texcoord:TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal: TEXCOORD0;
                float3 worldPos: TEXCOORD1;
                float2 uv:TEXCOORD2;
            };
            

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                //o.uv=v.texcoord.xy*_MainTex_ST.xy+_MainTex_ST.zw;
                //或者直接用API
                o.uv=TRANSFORM_TEX(v.texcoord, _MainTex); //这里的uv就是最终的纹理坐标

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // blinn-phong model:world space
                
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));  //注意API前面要有Unity,没Unity的版本已经弃用了
                fixed3 worldHalfDir = normalize(worldLightDir+worldViewDir);
                fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldHalfDir,i.worldNormal)),_Gloss);

                fixed3 albedo = tex2D(_MainTex,i.uv).rgb*_Color.rgb;
                fixed3 halfLambert = dot(worldLightDir,i.worldNormal);
                fixed3 diffuse = _LightColor0.rgb*albedo*max(0,dot(worldLightDir,i.worldNormal));

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
