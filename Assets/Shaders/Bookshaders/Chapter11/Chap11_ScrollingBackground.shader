Shader "ShaderBook/Chapter11/Chap11_ScrollingBackground"
{
    Properties
    {
        _MainTex ("Base Layer(RGB)", 2D) = "white" {} //对应第一层(较远)的背景纹理
        _DetailTex ("2nd Layer(RGB)", 2D) = "white" {} //对应第二层(较近)的背景纹理
        _ScrollX ("Base layer scroll speed", Float) = 1.0
        _Scroll2X ("2nd layer scroll speed", Float) = 1.0
        _Multiplier ("Layer Multiplier", Float) = 1 //用于控制纹理的整体亮度
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}

        Pass
        {
            Tags {"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DetailTex;
            float4 _DetailTex_ST;
            float _ScrollX;
            float _Scroll2X;
            float _Multiplier;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //在水平方向上对纹理坐标进行偏移,以此达到滚动的效果, frac:取小数部分,这样_ScrollX*Time.y大于1的时候就会重新回到0的位置
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex) + frac(float2(_ScrollX, 0.0)* _Time.y);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _DetailTex) + frac(float2(_Scroll2X, 0.0)* _Time.y);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 firstLayer = tex2D(_MainTex, i.uv.xy);
                fixed4 secondLayer = tex2D(_DetailTex, i.uv.zw);
                //使用第二层纹理(比较近的那张)的透明通道来混合两张纹理
                fixed4 c = lerp(firstLayer, secondLayer, secondLayer.a);
                c.rgb *= _Multiplier;
                return c;
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
