Shader "ShaderBook/Chapter12/Chap12_EdgeDetection"
{
    //在实际应用中,物体的纹理,阴影等信息均会影响边缘检测的结果,使得结果包含许多非预期的描边.
    //为了得到更加准确的边缘信息,往往会在屏幕的深度纹理和法线纹理上进行边缘检测,详见13.4节
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _EdgeOnly("Edge Only",Float) = 1.0
        _EdgeColor("Edge Color",Color)=(0,0,0,1)
        _BackgroundColor("Background Color",Color)=(1,1,1,1)
    }
    SubShader
    {
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            struct v2f
            {
                half2 uv[9] : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            half4 _MainTex_TexelSize;  // 1/512 * 1/512  https://www.jianshu.com/p/f2b2d504c212
            float _EdgeOnly;
            fixed4 _EdgeColor;
            fixed4 _BackgroundColor;

            v2f vert (appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //把计算采样纹理坐标的代码从片元着色器中转移到顶点着色器中,可以减少运算,提高性能
                //由于从顶点着色器到片元着色器的插值是线性的,因此这样的转移不会影响纹理计算的结果
                half2 uv = v.texcoord;
                o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1,-1);
                o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0,-1);
                o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1,-1);
                o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1,0);
                o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0,0);
                o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1,0);
                o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1,1);
                o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0,1);
                o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1,1);
                
                return o;
            }

            fixed luminance(fixed4 color)
            {
                return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
            }

            half Sobel(v2f i)
            {
                const half Gx[9] = {-1, 0, 1,
                                    -2, 0, 2,
                                    -1, 0, 1};
                const half Gy[9] = {-1, -2, -1,
                                    0, 0, 0,
                                    1, 2, 1};
                half texColor;
                half edgeX = 0;
                half edgeY = 0;
                for(int it = 0; it < 9; it++)
                {
                    texColor = luminance(tex2D(_MainTex, i.uv[it]));
                    edgeX += texColor * Gx[it];
                    edgeY += texColor * Gy[it];
                }
                //根据Sobel算子公式,|Gx|+|Gy|越大,越有可能是边缘
                half edge = 1-abs(edgeX)-abs(edgeY);  //edge越小,表明该位置越可能是一个边缘点
                //测试只提取x边缘
                //edge = 1-abs(edgeX);
                return edge;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                half edge = Sobel(i);
                //edge越小,越可能是一个边缘点,withEdgeColor会越接近边缘的设定颜色
                fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex,i.uv[4]),edge);
                fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
                return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
                
            }
            ENDCG
        }
    }
    Fallback Off
}
