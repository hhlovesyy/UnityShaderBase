Shader "ShaderBook/Chapter11/Chap11_Billboard"
{
    /*
    使用Unity的quad作为广告牌,而不能使用plane.这是因为代码建立在一个竖直摆放的多边形的基础上.
    多边形的顶点结构满足在模型空间下竖直排列,这样才能使用v.vertex计算得到正确的相对于中心的位置偏移量
    */
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color Tint", Color) = (1,1,1,1)
        _VerticalBillboarding ("Vertical Restraints", Range(0,1))=1 //调整是固定法线还是固定指向上的方向,即约束垂直方向的程度
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" 
            "RenderType"="Transparent" "DisableBatching"="True" }
        //广告牌技术中,我们需要使用物体的模型空间下的位置来作为锚点进行计算,所以要取消批处理

        Pass
        {
            Tags {"LightMode"="ForwardBase"}
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            
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
            float _VerticalBillboarding;
            
            v2f vert (a2v v)
            {
                v2f o;
                //选择模型空间的原点作为广告牌的原点
                float3 center = float3(0,0,0);
                //利用内置变量获取模型空间下的摄像机位置
                float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1));
                float3 normalDir = viewer - center;
                //如果_VerticalBillboarding是1,则法线方向固定为视角方向,
                //否则如果_VerticalBillboarding是0的话,则向上方向固定为(0,1,0),此时相当于在y轴投影
                normalDir.y = normalDir.y * _VerticalBillboarding;
                normalDir = normalize(normalDir);  //归一化法线方向


                //Get the approximate up dir
                //If normal dir is already towards up, then the up dir is towards front
                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1):float3(0, 1, 0);
                float3 rightDir = normalize(cross(upDir, normalDir));
                upDir = normalize(cross(normalDir, rightDir));
                //至此,我们得到了所需的3个正交基矢量
                // float3 centerOffs = v.vertex.xyz - center;
                // float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;
                // o.pos = UnityObjectToClipPos(float4(localPos,1));

                //https://zhuanlan.zhihu.com/p/530580235
                //采用矩阵乘法的方式可能更好理解,如下:
                float3x3 objTrans = {
                    rightDir.x, upDir.x, normalDir.x,
                    rightDir.y, upDir.y, normalDir.y,
                    rightDir.z, upDir.z, normalDir.z,
                };

                float3 localPos = mul(objTrans, v.vertex);
                o.pos = UnityObjectToClipPos(float4(localPos,1));
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 c = tex2D(_MainTex, i.uv);
                c.rgb *= _Color.rgb;
                return c;
            }
            ENDCG
        }
    }
    Fallback "Transparent/VertexLit"
}
