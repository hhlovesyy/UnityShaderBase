Shader "Test/Test_DecalShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TransparentScale("TransparentScale",Float) = 0.8
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"
            "Queue"="Geometry+1" }
        ZWrite Off
        ZTest Off
        Cull Front
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
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
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _CameraDepthTexture;
            float _TransparentScale;

            v2f vert (a2v v)
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
                float3 ndcPos = screenPos/screenPos.w * 2 - 1;
                float3 clipPos = float3(ndcPos.x, ndcPos.y, 1) * _ProjectionParams.z;
                float3 viewPos = mul(unity_CameraInvProjection, clipPos.xyzz).xyz * depth;
                float3 worldPos = mul(UNITY_MATRIX_I_V, float4(viewPos, 1.0)).xyz;
                return worldPos;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = DepthToWorldPosition(i.screenPos);
                float4 objectPos = mul(unity_WorldToObject, float4(worldPos, 1.0));
                clip(float3(0.5,0.5,0.5)-abs(objectPos.xyz));

                //fixed4 color = fixed4(1,0,0,1);
                float2 decalUv = float2(objectPos.x,objectPos.z) + 0.5;
                fixed4 color = tex2D(_MainTex, decalUv);
                return fixed4(color.rgb, color.a * _TransparentScale);
            }
            ENDCG
        }
    }
}
