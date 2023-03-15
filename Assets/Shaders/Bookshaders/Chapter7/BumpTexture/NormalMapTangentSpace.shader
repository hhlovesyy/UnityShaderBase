Shader "ShaderBook/Chapter7/NormalMapTangentSpace"
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
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            fixed4 _Specular;
            float _Gloss;
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpTex;
            float4 _BumpTex_ST;  //无论是否两套纹理复用同一套纹理坐标,_ST都是需要的
            float _BumpScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent: TANGENT;  //和normal不同,需要tangent.w分量决定切线空间中的第三个坐标轴-副切线的方向性
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;  //_MainTex和_BumpTex通常会使用同一组纹理坐标,因此可以只计算和存储一个纹理坐标即可,但ST不同,所以要存四个量
                float3 lightDir:TEXCOORD1;
                float3 viewDir:TEXCOORD2; //存储转换到切线空间的值,方便在片元着色器中计算 
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpTex);

                //change model space to tangent space
                //float3 binormal = cross(normalize(v.normal),normalize(v.tangent.xyz))*v.tangent.w; //y=cross(z,x),和z,x都垂直的方向有两个,w分量会决定采用哪一个
                //float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);

                //or
                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               //in tangent space
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                fixed4 packedNormal = tex2D(_BumpTex, i.uv.zw);
                fixed3 tangentNormal;
                // tangentNormal.xy = (packedNormal.xy*2-1)*_BumpScale;
                // tangentNormal.z = sqrt(1.0-saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                //Or if the texture is marked as "normal map"
                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0-saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                //light model
                fixed3 halfDir = normalize(tangentLightDir+tangentViewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(halfDir,tangentNormal)),_Gloss);

                fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = albedo * _LightColor0.rgb * max(0, dot(tangentNormal,tangentLightDir));

                fixed3 color = ambient + diffuse + specular;
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
    Fallback "Specular"
}
