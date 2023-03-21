Shader "ShaderBook/Chapter9/ForwardRendering"
{
    //base:Blinn Phong
    Properties
    {
        _Specular("Specular", Color)=(1,1,1,1)
        _Gloss("Gloss", Range(0,256))=80
        _Diffuse("Diffuse",Color)=(1,1,1,1)
    }
    SubShader
    {
        Pass
        {
            // pass for ambient light & first pixel light(directional light)
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            //Apparently need to add this declaration
            #pragma multi_compile_fwdbase //保证在shader中使用光照衰减等光照变量时可以被正确赋值
            #pragma enable_d3d11_debug_symbols  //让renderdoc不会优化掉
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float3 worldPos:TEXCOORD0;
                float3 worldNormal:TEXCOORD1;
                float4 pos : SV_POSITION;
            };

            float _Gloss;
            fixed3 _Diffuse;
            fixed3 _Specular;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                fixed3 halfDir = normalize(worldLightDir+worldViewDir);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0,dot(i.worldNormal, worldLightDir));
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(halfDir,i.worldNormal)),_Gloss);

                //The attenuation of directional light is always 1
                fixed atten = 1.0;
                return fixed4(ambient + (diffuse + specular) * atten, 1.0);
                
            }
            ENDCG
        }
        
        Pass
        {
            //Pass for other pixel lights
            Tags{"LightMode"="ForwardAdd"}
            Blend One One
            CGPROGRAM
            //Apparently need to add this declaration
            #pragma multi_compile_fwdadd

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            //Apparently need to add this declaration
            #pragma multi_compile_fwdbase //保证在shader中使用光照衰减等光照变量时可以被正确赋值
            #pragma enable_d3d11_debug_symbols  //让renderdoc不会优化掉
            //大体上与base pass是一致的,但是我们需要做出一些修改
            //去掉Bass Pass中的环境光,自发光,逐顶点光照,SH光照的部分,并添加一些对不同光源类型的支持
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float3 worldPos:TEXCOORD0;
                float3 worldNormal:TEXCOORD1;
                float4 pos : SV_POSITION;
            };

            float _Gloss;
            fixed3 _Diffuse;
            fixed3 _Specular;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //由于Additional Pass处理的光源类型可能是平行光,点光源或者聚光灯,因此要分类讨论
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                #else
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                #endif
                
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir+worldViewDir);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0,dot(i.worldNormal, worldLightDir));
                //不需要再计算环境光
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(halfDir,i.worldNormal)),_Gloss);

                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed atten = 1.0;
                #else
                    //尽管可以用数学表达式来计算给定点对于点光源和聚光灯的衰减,但计算往往涉及开根号除法等计算量较大的操作.
                    //Unity用了一张纹理作为查找表LUT,以在片元着色器中得到光源的衰减;
                    /*
                     * (1)首先,得到光源空间下的坐标;
                     * (2)使用该坐标对衰减纹理进行采样得到衰减值;
                     * 关于相关的细节可以参考9.3节,整理如下:
                     * Unity在内部使用_LightTexture0的纹理来计算光照衰减,如果对光源使用了cookie,则衰减查找纹理是_LightTextureB0,这里不讨论.
                     * // https://docs.unity.cn/cn/2020.3/Manual/Cookies.html
                     * 通常只关心_LightTexture0对角线上的纹理颜色值,(0,0)表明了与光源位置重合的点的衰减值,(1,1)则表明了在光源空间中所关心的距离最远的点的衰减
                     */
                    #if defined (POINT)
                        //注意引入AutoLight.cginc
                        float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                        fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #elif defined (SPOT)
                        /*
                         * 与点光源不同，由于聚光灯有更多的角度等要求，因此为了得到衰减值，除了需要对衰减纹理采样外，还需要对聚光灯的范围、张角和方向进行判断
                         * 此时衰减纹理存储到了_LightTextureB0中，这张纹理和点光源中的_LightTexture0是等价的
                         * 聚光灯的_LightTexture0存储的不再是基于距离的衰减纹理，而是一张基于张角范围的衰减纹理,在AutoLight.cginc中有这样一个函数:UnitySpotCookie,后面可以读一下源码
                         */
                        float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
				        fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w
                                    * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #else
                        fixed atten = 1.0;
                    #endif
                #endif
                
                //The attenuation of directional light is always 1
                return fixed4((diffuse + specular) * atten, 1.0);
                
            }

            ENDCG
        }
    }
    Fallback "Specular"
}
