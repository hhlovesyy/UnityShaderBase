using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ScreenGlobalEffect : PostEffectBase
{
    public Shader screenShader;
    private Material screenMaterial;
    public Texture2D screenImage;

    public Material material
    {
        get
        {
            screenMaterial = CheckShaderAndCreateMaterial(screenShader, screenMaterial);
            return screenMaterial;
        }
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            material.SetTexture("_ScreenTex", screenImage);
            material.SetFloat("_nowTime",Time.time);
            Graphics.Blit(src, dest, material, 0);
        }
        else
        {
            Graphics.Blit(src,dest);
        }
    }
}
