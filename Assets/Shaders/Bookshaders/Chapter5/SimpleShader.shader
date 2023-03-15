Shader "ShaderBook/Chapter5/SimpleShader"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            struct a2v
            {
                float4 vertex:POSITION;
                float3 normal:NORMAL; //填充的都是模型空间的变量,这些语义由材质的Mesh Render提供
                //每帧调用draw call的时候,Mesh Render组件会把其负责渲染的模型数据发给Unity Shader
                float4 texcoord:TEXCOORD0;
            };

            struct v2f
            {
                float4 pos:SV_POSITION;
                fixed3 color:COLOR0;
                //fixed3 worldNormal:TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //(1)下面的两句打开的话可以根据世界空间的法线方向决定颜色(在片元着色器中对颜色插值)
                // float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                // o.color = worldNormal*0.5+fixed3(0.5,0.5,0.5);

                //(2)下面一句是根据模型空间的法线,所以旋转模型的时候颜色也会跟着变(比如说本来上面蓝色,往右旋转右边会变成蓝色,颜色是跟着模型动的)
                o.color = v.normal * 0.5 + fixed3(0.5,0.5,0.5); //normal的范围是-1.0~1.0

                //(3)下面一句会把世界空间下的法线直接存储起来,在片元着色器里插值
                //o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                //(1)对应(1)(2)的写法
                return fixed4(i.color, 1.0);

                //(3)对应3的写法
                // fixed3 color = i.worldNormal*0.5+fixed3(0.5,0.5,0.5);
                // return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}
