Shader "ShaderBook/Chapter11/Chap11_Water"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color Tint", Color) = (1,1,1,1)
        _Magnitude("Distortion Magnitude", Float) = 1  //水流波动的幅度
        _Frequency("Distortion Frequency", Float) = 1  //水流波动的频率
        _InvWaveLength("Distortion Inverse Wave Length", Float) = 10  //用于控制波长的倒数(该值越大,波长越小)
        _Speed("Speed", Float) = 0.5 //控制河流纹理的移动速度
        
    }
    SubShader
    {
        //为透明效果设置合适的标签
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" 
            "RenderType"="Transparent" "DisableBatching"="True"}
        //需要说明的是,上述标签设置取消了对该shader的批处理操作,这是因为批处理会合并所有相关的模型,而各自对应的模型空间就会丢失.
        //在本例中,我们需要在物体的模型空间下对顶点位置进行偏移,因此需要取消批处理操作

        Pass
        {
            Tags {"LightMode"="ForwardBase"}
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off //以上三条指令是为了让水流的每个面都能显示
            
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
            float _Magnitude;
            float _Frequency;
            float _InvWaveLength;
            float _Speed;
            
            v2f vert (a2v v)
            {
                v2f o;
                float4 offset;
                /*
                 * 首先计算顶点位移量,只希望对顶点的x方向位移,因此yzw的位移量被设置为0
                 * 利用_Frequency属性和内置的_Time.y变量控制正弦函数的频率.
                 * 具体说明见笔记部分.
                 */
                offset.yzw = float3(0.0,0.0,0.0);
                offset.x = sin(_Frequency * _Time.y + v.vertex.x * _InvWaveLength
                    + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;
                o.pos = UnityObjectToClipPos(v.vertex + offset);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv += float2(0.0, _Time.y * _Speed);  //这个是只对纹理进行偏移,并且是v方向的,也是因为模型的uv方向不太一样,水平移动纹理表示v方向,进入到项目测试就能发现了.
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
        //为了正确渲染阴影,加入一个ShadowCaster Pass,暂时懂得用法就行,原理后面研究
        Pass
        {
            Tags {"LightMode"="ShadowCaster"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            float _Magnitude;
            float _Frequency;
            float _InvWaveLength;
            float _Speed;
            
            struct v2f
            {
                V2F_SHADOW_CASTER;  //定义阴影投射需要定义的变量
            };

            v2f vert(appdata_base v) //appdata_base 包括vertex,texcoord和normal
            {
                v2f o;
                float4 offset;
                offset.yzw = float3(0.0,0.0,0.0);
                offset.x = sin(_Frequency * _Time.y + v.vertex.x * _InvWaveLength
                    + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;
                v.vertex = v.vertex+offset;

                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)  //让unity自动帮我们完成剩下的工作(代码逻辑有时间再看)
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i);  //让Unity自动完成阴影投射的部分,把结果输出到深度图和shadowmap当中
            }
            
            ENDCG
        }
    }
    
    //Fallback "Transparent/VertexLit"
    Fallback "VertexLit" //可以查看阴影
}
