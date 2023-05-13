using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class MotionBlur : PostEffectBase
{
    public Shader motionBlurShader;
    private Material motionBlurMaterial = null;

    public Material material
    {
        get
        {
            motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
            return motionBlurMaterial;
        }
    }
    [Range(0.0f,0.9f)] public float blurAmount = 0.5f;  //运动模糊在混合图像时使用的模糊参数
    private RenderTexture accumulationTexture; //保存之前图像叠加的结果

    void OnDisable()  //每当脚本被禁用(不运行)的时候都会执行一次回调函数
    {
        DestroyImmediate(accumulationTexture);
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            //Create the accumulation texture
            if (accumulationTexture == null || accumulationTexture.width != src.width ||
                accumulationTexture.height != src.height)
            {
                DestroyImmediate(accumulationTexture);
                accumulationTexture = new RenderTexture(src.width, src.height, 0);
                accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
                Graphics.Blit(src, accumulationTexture);
            }
            
            //We are accumulating motion over frames without clear/discard
            accumulationTexture.MarkRestoreExpected();  //本来是希望这张RenderTexture保持它当前的样子而不是在渲染完每一帧后销毁掉他,但是在较高的Unity版本里这句话已经不需要了
            material.SetFloat("_BlurAmount",1.0f-blurAmount);
            Graphics.Blit(src,accumulationTexture,material); //没有指定pass的话pass默认是-1,依次调用shader中的所有pass
            Graphics.Blit(accumulationTexture,dest);
        }
        else
        {
            Graphics.Blit(src,dest);
        }
    }
}
