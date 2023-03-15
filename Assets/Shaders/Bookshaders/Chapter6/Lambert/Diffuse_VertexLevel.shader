Shader "ShaderBook/Chapter6/Diffuse Vertex-Level"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1,1,1,1)
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

            fixed4 _Diffuse;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
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
                
                //Lambert model,world space
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  //已经归一化完了
                //上面代码不用API的话是：
                fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz); //获取光源的方向,但不具有通用性(多光源不适用)
                //在正确的LightMode标签下，_LightColor0可以访问该Pass处理的光源的颜色和强度信息
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                o.color = ambient + diffuse;
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(i.color, 1.0);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
