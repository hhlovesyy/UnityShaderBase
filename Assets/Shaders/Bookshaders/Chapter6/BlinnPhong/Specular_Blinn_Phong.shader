Shader "ShaderBook/Chapter6/Specular_BlinnPhong"
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
                fixed3 worldNormal : TEXCOORD0;
                float3 worldPos: TEXCOORD1;
            };
            

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //Lambert part: world space
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));  //注意归一化,这个API是不会归一化的
                fixed3 diffuse = _Diffuse.rgb * _LightColor0.rgb * saturate(dot(i.worldNormal, worldLightDir));
                
                //Blinn Phong part
                //Blinn Phong光照模型的高光部分看起来更大,更亮一些,实际渲染中大多数情况会采用Blinn-Phong模型,在一些情况下该模型更符合实验结果.
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos)); //一样别忘了归一化,该API不会自己归一化
                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * pow(max(0, dot(i.worldNormal,worldHalfDir)), _Gloss);

                //fixed3 color = ambient + specular;  //打开这行可以只查看高光的区域
                fixed3 color = ambient + diffuse + specular;
                return fixed4(color, 1.0);
            }
            ENDCG
        }
    }
    Fallback "Specular"
}
