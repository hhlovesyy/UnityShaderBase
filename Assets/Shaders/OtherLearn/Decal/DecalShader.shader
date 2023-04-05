Shader "OtherShader/DecalShader"
{
    Properties
    {
        _MainTex("MainTex", 2D)="white" {}    
    }
    
    SubShader
    {
        //不想让贴花被后面绘制的物体盖住
        Tags{"RenderType"="Opaque"
                "Queue"="Geometry+1"}
        ZWrite Off //绘制贴花物体依赖于深度图,贴花本身的Cube要做Zwrite Off处理
        ZTest Off
        
        //Cull Front:如果相机在cube内部,cull back会导致cube没有机会去绘制,导致看不见贴画效果
        //如果是Cull Front,则在里面在外面都不会有问题
        Cull Front
        Blend SrcAlpha OneMinusSrcAlpha  //处理透明混合用的

        Pass
        {
            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            float4 _MainTex_ST;

            //global texture that holds depth information
            sampler2D _CameraDepthTexture;

            struct a2v
            {
                float4 vertex: POSITION;
                float4 texcoord: TEXCOORD0;
            };

            struct v2f
            {
                float4 pos: SV_POSITION;
                float4 screenPos: TEXCOORD0;
                float2 uv: TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.screenPos = ComputeScreenPos(o.pos);
                return o;
            }

            float3 DepthToWorldPosition(float4 screenPos)
            {
                float depth = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, screenPos)));
                float4 ndcPos = (screenPos/screenPos.w) * 2 - 1; //map[0,1]->[-1,1]
                float3 clipPos = float3(ndcPos.x, ndcPos.y, 1) * _ProjectionParams.z; //z=far plane=mvp result w
                float3 viewPos = mul(unity_CameraInvProjection, clipPos.xyzz).xyz * depth;
                float3 worldPos = mul(UNITY_MATRIX_I_V, float4(viewPos,1)).xyz;
                return worldPos;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 worldPos = DepthToWorldPosition(i.screenPos);
                float4 localPos = mul(unity_WorldToObject, float4(worldPos, 1.0));
                clip(float3(0.5,0.5,0.5)-abs(localPos.xyz));  //Cube的四个角都是坐标都是0.5

                //handle uv & sample texture
                fixed2 decalUV = fixed2(localPos.x, localPos.z);
                decalUV = decalUV + 0.5; //[-0.5,0.5]->[0,1]
                fixed4 color = tex2D(_MainTex, decalUV);
                //fixed4 color = fixed4(1,0,0,1);
                return color;
            }

            ENDCG
        }
    }
    
    //Fallback "Diffuse"  加上这句就会出问题,后面总结一下为什么
}
