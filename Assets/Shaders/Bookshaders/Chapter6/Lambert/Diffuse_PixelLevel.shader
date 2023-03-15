Shader "ShaderBook/Chapter6/Diffuse Pixel-Level"
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
                float4 pos : SV_POSITION;
                fixed3 worldNormal: TEXCOORD0;  //存储的类型以后尽量统一,就用TEXCOORD系列吧
            };
            
            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //Lambert model:world space
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _Diffuse.rgb * _LightColor0.rgb * saturate(dot(worldLightDir, i.worldNormal));

                fixed3 color = ambient+diffuse;
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}
