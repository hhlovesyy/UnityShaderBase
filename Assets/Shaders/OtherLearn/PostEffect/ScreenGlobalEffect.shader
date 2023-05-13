// 用于实现屏幕效果,比如受伤血迹这种的Shader, 但具体的混合还有一些疑问,后面看一下.
Shader "Other/ScreenGlobalEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ScreenTex ("Texture", 2D) = "red" {}
        _Speed("Speed",Float) = 1.0
        _nowTime("now time", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
        ZTest Always Cull Off ZWrite Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _ScreenTex;
            float _Speed;
            float _nowTime;

            v2f vert (appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = v.texcoord;
                o.uv.zw = v.texcoord;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv.xy);
                fixed4 screenCol = tex2D(_ScreenTex, i.uv.zw);
                fixed alpha = screenCol.a;
                alpha = alpha * ( sin(_Time.y * 10) * 0.5 + 0.5);
                //fixed4 newScreencol = fixed4(screenCol.rgb, screenCol.a);
                //alpha *= 0.5;
               
                fixed4 lerpRGB = lerp(col,screenCol,alpha);
                return lerpRGB;
                //return screenCol;
                //return newScreencol;
            }
            ENDCG
        }
    }
}
