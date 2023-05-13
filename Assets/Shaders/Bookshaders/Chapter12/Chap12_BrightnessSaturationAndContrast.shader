Shader "ShaderBook/Chapter12/Chap12_BrightnessSaturationAndContrast"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}  //Graphics.Blit会把第一个参数传递给_MainTex,因此不能改名
        _Brightness("Brightness", Float)=1
        _Saturation("Saturation", Float)=1
        _Contrast("Contrast", Float)=1    
    }
    SubShader
    {
        Pass
        {
            //关闭深度写入,防止挡住后面的物体,这些状态可以认为是用于屏幕后处理的"标配"
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _Brightness;
            half _Contrast;
            half _Saturation;

            v2f vert (appdata_img v)  //appdata_img包含vertex和texcoord
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 renderTex = tex2D(_MainTex, i.uv);
                //Apply brightness
                fixed3 finalColor = renderTex.rgb * _Brightness;

                //Apply saturation
                //计算luminance,每个颜色分量乘以一个特定系数再相加得到
                //luminance的介绍详见：https://stackoverflow.com/questions/596216/formula-to-determine-perceived-brightness-of-rgb-color
                //luminance的概念忘记了的话需要复习一下Games101,其实就是Radiance
                //概念可参考这个链接:https://www.cnblogs.com/zlbg/p/4049962.html
                fixed luminance = 0.2126 * renderTex.r + 0.7152 * renderTex.g + 0.0722 * renderTex.b;
			    fixed3 luminanceColor = fixed3(luminance, luminance, luminance); //灰度图,R=G=B就是灰度图
                finalColor = lerp(luminanceColor, finalColor, _Saturation);  //a + w*(b-a) ,也就是说w没有限制一定在0-1之间,可以调整w>1看看shader的情况

                //Apply contrast
                fixed3 avgColor = fixed3(0.5,0.5,0.5); //纯灰色
                finalColor = lerp(avgColor, finalColor, _Contrast);
                return fixed4(finalColor, renderTex.a);
            }
            ENDCG
        }
    }
    Fallback Off
}
