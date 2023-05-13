Shader "ShaderBook/Chapter12/Chap12_MotionBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurAmount("Blur Amount", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"
        sampler2D _MainTex;
        fixed _BlurAmount;

        struct v2f
        {
            float4 pos: SV_POSITION;
            half2 uv:TEXCOORD0;
        };

        v2f vert(appdata_img v)
        {
            v2f o;
            o.pos =UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            return o;
        }
        //以下定义了两个片元着色器,一个用于更新渲染纹理的RGB通道部分,一个用于更新渲染纹理的A通道部分
        fixed4 fragRGB(v2f i): SV_Target
        {
            return fixed4(tex2D(_MainTex,i.uv).rgb, _BlurAmount);
        }
        half4 fragA(v2f i): SV_Target  //为了维护渲染纹理的透明通道值,不让其受到混合时使用的透明度值的影响
        {
            return tex2D(_MainTex, i.uv); 
        }
        
        ENDCG

        ZTest Always Cull Off ZWrite Off
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ColorMask RGB
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragRGB
            ENDCG
        }
        Pass
        {
            Blend One Zero
            ColorMask A
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragA
            ENDCG
        }
    }
    Fallback Off
}
