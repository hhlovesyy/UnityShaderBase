Shader "ShaderBook/Chapter10/Chapter10_GlassRefraction"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D)="bump" {}
        _Cubemap ("Environment Cubemap", Cube)="_Skybox" {}
        _Distortion ("Distortion", Range(0,1000))=10  //控制模拟折射时图像的扭曲程度
        _RefractAmount ("Refract Amount", Range(0.0,1.0)) = 1.0  //控制折射程度,为0时玻璃只包含反射效果,为1时该玻璃只包括折射效果
    }
    SubShader
    {
        //We must be transparent, so other objects are drawn before this one
        Tags { "RenderType"="Opaque" "Queue"="Transparent" } //这里的RenderType的介绍详见第13章
        
        //This Pass grabs the screen behind the object into the texture
        //We can access the result in the next pass as _ReflectionTex
        GrabPass {"_RefractionTex"}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            samplerCUBE _Cubemap;
            float _Distortion;
            fixed _RefractAmount;
            sampler2D _RefractionTex; //GrabPass会渲染屏幕图像在这里
            float4 _RefractionTex_TexelSize; //可以得到上面纹理的纹素大小.比如大小为256*512的纹理,纹素大小为(1/256,1/512)
            
            struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; 
				float2 texcoord: TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;  
			    float4 TtoW1 : TEXCOORD3;  
			    float4 TtoW2 : TEXCOORD4; 
			};

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
            	
                o.scrPos = ComputeGrabScreenPos(o.pos); //得到对应被抓取的屏幕图像的采样坐标
            	//与ComputeScreenPos基本类似,但最大的不同是针对平台差异造成的采样坐标问题进行了处理

            	float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
            	fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
            	fixed3 worldTangent = UnityObjectToWorldDir(v.tangent);
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
            	o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
            	o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
            	o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
            	
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
            	fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

            	fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
            	//compute the offset in tangent space
            	float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
            	i.scrPos.xy = i.scrPos.xy + offset; //选择使用切线空间下的法线方向来进行偏移,是因为该空间下的法线可以反映顶点局部空间下的法线方向
            	fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;  //屏幕坐标偏移模拟折射项,透视除法得到真正的屏幕坐标

            	//convert the normal to world space
            	bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
            	fixed3 reflDir = reflect(-worldViewDir, bump); //反射项计算
            	fixed4 texColor = tex2D(_MainTex, i.uv.xy);
            	fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb;
            	fixed3 finalColor = reflCol * (1-_RefractAmount) + refrCol * _RefractAmount;
            	
                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}
