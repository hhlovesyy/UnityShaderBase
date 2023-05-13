Shader "ShaderBook/Chapter12/Chap12_Bloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize ("Blur Size",Float) = 1.0
        _Bloom("Bloom(RGB)",2D) = "black" {}  //对应cs脚本传入的高斯模糊后的较亮区域
        _LuminanceThresold("Luminance Thresold", Float) = 0.5  //提取较亮区域的阈值
    }
    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        float _BlurSize;
        sampler2D _Bloom;
        float _LuminanceThresold;

        //以下定义提取较亮区域所需要的顶点着色器和片元着色器
        struct v2f
        {
            float4 pos:SV_POSITION;
            half2 uv:TEXCOORD0;
        };

        v2f vertExtractBright(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            return o;
        }

        fixed luminance(fixed4 color)
        {
            return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
        }

        fixed4 fragExtractBright(v2f i):SV_Target
        {
            fixed4 c = tex2D(_MainTex, i.uv);
            //clamps x to the range [min,max]
            fixed val = clamp(luminance(c)-_LuminanceThresold,0.0,1.0);   //https://blog.csdn.net/a6627651/article/details/50680360
            return c * val;
        }

        //以下定义混合亮部图像和原图像时所使用的顶点着色器和片元着色器
        struct v2fBloom
        {
            float4 pos:SV_POSITION;
            half4 uv:TEXCOORD0;
        };

        v2fBloom vertBloom(appdata_img v)
        {
            v2fBloom o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv.xy = v.texcoord;  //xy存储原图_MainTex的纹理采样坐标
            o.uv.zw = v.texcoord;   //zw存储_Bloom,也就是模糊后的较亮区域的纹理采样坐标

            //在入门精要p115页有提到这段代码的含义
            #if UNITY_UV_STARTS_AT_TOP
            if(_MainTex_TexelSize.y < 0.0)  //这段代码的含义可以参考:https://blog.csdn.net/wpapa/article/details/72721185,用来处理不同平台的纹理翻转情况
                o.uv.w = 1.0 - o.uv.w;
            #endif
            return o;
        }

        fixed4 fragBloom(v2fBloom i): SV_Target
        {
            return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);  //两张纹理做颜色混合
        }
        
        ENDCG
        
        ZTest Always Cull Off Zwrite Off
        //接下来是定义这个Shader的4个Pass
        Pass
        {
            CGPROGRAM
            #pragma vertex vertExtractBright
            #pragma fragment fragExtractBright
            ENDCG
        }
        //Unity内部会把所有Pass的Name转换成大写字母表示,因此在使用UsePass命令时必须使用大写形式的名字
        UsePass "ShaderBook/Chapter12/Chap12_GaussianBlur/GAUSSIAN_BLUR_VERTICAL"
        UsePass "ShaderBook/Chapter12/Chap12_GaussianBlur/GAUSSIAN_BLUR_HORIZONTAL"
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vertBloom
            #pragma fragment fragBloom
            ENDCG
        }
    }
    Fallback Off
}
