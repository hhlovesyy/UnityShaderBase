Shader "ShaderBook/Chapter12/Chap12_GaussianBlur"
{
    //这个Shader可以顺便学习到顶点着色器和片元着色器复用的技术
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize ("Blur Size",Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE //类似于C++的头文件,这里的代码可以被复用

        #include "UnityCG.cginc"
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        float _BlurSize;

        struct v2f
        {
            float4 pos: SV_POSITION;
            half2 uv[5]: TEXCOORD0;
        };

        v2f vertBlurVertical(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            half2 uv = v.texcoord;
            o.uv[0] = uv;
            o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
            o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize; //其他参数不变的时候,_BlurSize增大会提高模糊程度,但太大会造成虚影
            return o;
        }

        v2f vertBlurHorizontal(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            half2 uv = v.texcoord;
            o.uv[0] = uv;
            o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
            o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize; 
            return o;
        }

        fixed4 fragBlur(v2f i):SV_Target
        {
            float weight[3] = {0.4026, 0.2442, 0.0545};
            fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
            for(int it=1;it<3;it++)
            {
                sum+=tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
                sum+=tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];
            }
            return fixed4(sum,1.0);
        }
        
        ENDCG
        
        ZTest Always Cull Off ZWrite Off
        Pass
        {
            NAME "GAUSSIAN_BLUR_VERTICAL"  //为Pass定义名字,可以在其他Shader中直接通过名字来使用该Pass,见12.5节Bloom效果
            CGPROGRAM
            #pragma vertex vertBlurVertical
            #pragma fragment fragBlur
            ENDCG
        }
        Pass
        {
            NAME "GAUSSIAN_BLUR_HORIZONTAL"
            CGPROGRAM
            #pragma vertex vertBlurHorizontal
            #pragma fragment fragBlur
            ENDCG
        }
    }
    Fallback Off
}
