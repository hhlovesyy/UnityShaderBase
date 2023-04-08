Shader "ShaderBook/Chapter11/Chap11_ImageSequenceAnimation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color Tint", Color)=(1,1,1,1)
        _HorizontalAmount("Horizontal Amount", Float) = 4  //水平方向都多少帧,下面类似
        _VerticalAmount("Vertical Amount", Float) = 4
        _Speed("Speed", Range(1,100)) = 30
    }
    SubShader
    {
        //序列帧通常是透明纹理,此时记得勾选透明纹理的"Alpha is Transparency"属性
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
        
        Pass
        {
            Tags {"LightMode"="ForwardBase"}
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha  //a srcColor dstColor a*srcColor+(1-a)*dstColor
            
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
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _HorizontalAmount;
            float _VerticalAmount;
            float _Speed;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float time = floor(_Time.y * _Speed);  //_Time.y就是t,自场景加载开始的时间,与速度相乘可以得到模拟的时间,可以理解成速度乘时间得到了一个"位移"
                float row = floor(time / _HorizontalAmount); 
                float column = time - row * _HorizontalAmount; //除法得到的余数则是列索引,这里书上写的有误,可以看勘误:http://candycat1992.github.io/unity_shaders_book/unity_shaders_book_corrigenda.html
                //row和column记录的是第row行第col列
                /*
                 * 方便理解的代码:采样坐标需要映射到每个关键帧图像的坐标范围内
                 * half2 uv = float2(i.uv.x / _HorizontalAmount, i.uv.y / _VerticalAmount);
                 * uv.x += column / _HorizontalAmount;
                 * uv.y -= row / _VerticalAmount;
                 * 上面三行代码简化完之后就是下面的代码了.
                 */
                half2 uv = i.uv + half2(column, -row);
                uv.x /= _HorizontalAmount;
                uv.y /= _VerticalAmount;
                fixed4 c = tex2D(_MainTex, uv);
                c.rgb *= _Color;
                return c;
            }
            ENDCG
        }
    }
}
