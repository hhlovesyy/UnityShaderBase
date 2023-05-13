using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bloom : PostEffectBase
{
    public Shader bloomShader;
    private Material bloomMaterial = null;

    public Material material
    {
        get
        {
            bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
            return bloomMaterial;
        }
    }
    //Blur iterations - larger number means more blur
    [Range(0, 4)] public int iterations = 3;
    //Blur spread for each iteration - larger number means more blur
    [Range(0.2f, 3.0f)] public float blurSpread = 0.6f;  //见下方代码和Shader代码,控制采样距离
    [Range(1, 8)] public int downSample = 2;  //用于对图像整体下采样

    [Range(0.0f, 4.0f)] public float luminanceThresold;  //控制提取较亮区域时使用的阈值大小,之所以设定到可以调节到1以上是因为HDR
    
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat("_LuminanceThresold", luminanceThresold);
            int rtW = src.width / downSample;
            int rtH = src.height / downSample;
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0); //分配一块缓冲区
            buffer0.filterMode = FilterMode.Bilinear;
            Graphics.Blit(src,buffer0,material,0);  //用第一个Pass提取图像中的较亮区域,存储在buffer0当中

            for (int i = 0; i < iterations; i++)
            {
                material.SetFloat("_BlurSize", 1.0f+i*blurSpread);
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                //Render the vertical pass
                Graphics.Blit(buffer0, buffer1,material,1);
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                //Render the horizontal pass
                Graphics.Blit(buffer0, buffer1,material,2);
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }
            material.SetTexture("_Bloom", buffer0);  //把图像较亮区域提取出来,存储在渲染纹理中,并用高斯模糊对渲染纹理进行模糊操作,模拟bloom效果,最终得到的结果在buffer0中
            Graphics.Blit(src,dest,material,3);
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(src,dest);
        }
    }
}
