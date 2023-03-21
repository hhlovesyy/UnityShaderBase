Shader "ShaderBook/Chapter8/AlphaBlendZWrite"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color Tint",Color) = (1,1,1,1)
        _AlphaScale("Alpha Scale", Range(0, 1)) = 1
    }
    SubShader
    {
        //一般使用了透明度混合的Shader都应该在SubShader中设置这三个标签
        Tags { "Queue"="Transparent"
                "IgnoreProjector"="True"  //这个shader不会受到Projectors的影响
                "RenderType"="Transparent"} //可以让Unity把这个shader归入到提前定义的组
        
        //Extra pass that renders to depth buffer only
        Pass
        {
            ZWrite On
            ColorMask 0  //设置颜色通道的写掩码,语法 ColorMask RGB | A| 0等,设置为0时意味着该Pass不写入任何颜色通道,即不输出任何颜色
        }
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            ZWrite Off  //透明度混合,关闭深度写入
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL; 
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos: TEXCOORD1;
                float3 worldNormal: TEXCOORD2;
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 texColor = tex2D(_MainTex, i.uv);

                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                fixed3 albedo = texColor.rgb * _Color.rgb;
                fixed3 diffuse = albedo * _LightColor0.rgb * max(0, dot(i.worldNormal, worldLightDir));
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
            }
            ENDCG
        }
    }
    Fallback "Transparent/Cutout/VertexLit"  //具体原理参考9.4.5节
}
