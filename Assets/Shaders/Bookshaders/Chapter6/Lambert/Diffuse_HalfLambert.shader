Shader "ShaderBook/Chapter6/Half Lambert Pixel-Level"
{
    //半兰伯特模型的优势:传统的兰伯特模型在背光区域是完全黑暗的(因为在max(0,l·n)的时候被截断为0了),而半兰伯特模型可以在背光的地方也会亮一些
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

                //half-lambert,[-1,1]->[0,1]
                fixed3 halfLambertDotRes = dot(worldLightDir, i.worldNormal) * 0.5 + 0.5;
                fixed3 diffuse = _Diffuse.rgb * _LightColor0.rgb * saturate(halfLambertDotRes);
                
                fixed3 color = ambient+diffuse;
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}
