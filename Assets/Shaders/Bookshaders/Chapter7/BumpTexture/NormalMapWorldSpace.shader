Shader "ShaderBook/Chapter7/NormalMapWorldSpace"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpTex ("Texture", 2D) = "bump"{}
        _Gloss("Gloss", Range(8.0,256)) = 20
        _Color("Color", Color) = (1,1,1,1)
        _Specular("Specular", Color)=(1,1,1,1)
        _BumpScale("BumpScale", Float) = 1.0
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent: TANGENT;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3; //这三个值用来存储切线空间转到世界空间的矩阵
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpTex;
            float4 _BumpTex_ST;
            fixed4 _Specular;
            float _Gloss;
            fixed4 _Color;
            float _BumpScale;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpTex);

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;

                //切线空间转世界空间的矩阵:把worldTangent,worldBinormal,worldNormal按列排布
                //此时,世界空间转切线空间的矩阵应该是该矩阵的转置,而针对法线变换的话也是这个矩阵,这个地方难以理解的话可以看https://zhuanlan.zhihu.com/p/436015941
                //顺便用最后一维存储worldPos的相关信息
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);

                fixed3 bump = UnpackNormal(tex2D(_BumpTex, i.uv.zw));
                bump.xy *= _BumpScale;
                bump.z = sqrt(1.0-saturate(dot(bump.xy,bump.xy)));

                //将法线方向转换到世界空间
                bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

                //lambert+ambient+blinn-Phong
                fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;
                fixed3 ambient = albedo * UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump,worldLightDir));
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldHalfDir, bump)),_Gloss);
                return fixed4(ambient+diffuse+specular, 1.0);
            }
            ENDCG
        }
    }
}
