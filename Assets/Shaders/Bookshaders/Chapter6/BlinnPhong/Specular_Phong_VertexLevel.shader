Shader "ShaderBook/Chapter6/Specular_Phong_VertexLevel"
{
    Properties
    {
        _Diffuse("Diffuse", Color)=(1,1,1,1)
        _Specular("Specular",Color)=(1,1,1,1)
        _Gloss("Gloss", Float) = 8.0
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

            fixed3 _Diffuse;
            fixed3 _Specular;
            float _Gloss;
            
            struct a2v
            {
                float4 vertex : POSITION;
                fixed3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos: SV_POSITION;
                fixed3 color : COLOR0;
            };
            

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //Lambert part: world space
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _Diffuse.rgb * _LightColor0.rgb * saturate(dot(worldNormal, worldLightDir));
                
                //Phong part
                fixed3 worldReflectDir = normalize(reflect(-worldLightDir, worldNormal));
                fixed3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * pow(max(0, dot(worldViewDir, worldReflectDir)), _Gloss);

                //o.color = ambient + specular;  //打开这行可以只查看高光的区域
                o.color = ambient + diffuse + specular;
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(i.color,1.0);
            }
            ENDCG
        }
    }
    Fallback "Specular"
}
