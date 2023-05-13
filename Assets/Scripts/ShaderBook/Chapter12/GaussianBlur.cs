using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GaussianBlur : PostEffectBase
{
    public Shader gaussianBlurShader;
    private Material gaussianBlurMaterial = null;

    public Material material
    {
        get
        {
            gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader, gaussianBlurMaterial);
            return gaussianBlurMaterial;
        }
    }
    //Blur iterations - larger number means more blur
    [Range(0, 4)] public int iterations = 3;
    //Blur spread for each iteration - larger number means more blur
    [Range(0.2f, 3.0f)] public float blurSpread = 0.6f;  //见下方代码和Shader代码,控制采样距离
    [Range(1, 8)] public int downSample = 2;  //用于对图像整体下采样
    //以上两个参数都是处于性能的考虑

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            int rtW = src.width / downSample;
            int rtH = src.height / downSample;
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0); //分配一块与屏幕大小相同的缓冲区
            buffer0.filterMode = FilterMode.Bilinear;
            Graphics.Blit(src,buffer0);
            
            //考虑了高斯模糊的迭代次数
            for (int i = 0; i < iterations; i++)
            {
                material.SetFloat("_BlurSize", 1.0f + blurSpread * i);
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                //Render the vertical pass
                Graphics.Blit(buffer0,buffer1,material,0); 
                RenderTexture.ReleaseTemporary(buffer0); //释放之前分配的缓存
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);  //这句不写的话会出问题
                //Render the horizontal pass
                Graphics.Blit(buffer0, buffer1, material,1);
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;  //每轮迭代后最终的渲染结果放在buffer0当中
            }
            Graphics.Blit(buffer0,dest);
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(src,dest);
        }
    }
}
