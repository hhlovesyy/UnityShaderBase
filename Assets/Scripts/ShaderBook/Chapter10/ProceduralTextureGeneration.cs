using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ProceduralTextureGeneration : MonoBehaviour
{
    public Material material = null;

    #region Material properties
    
    public int textureWidth = 512;  //也可以如书中所说,采用开源插件SetProperty,不过这里为了方便起见就先不用了
    //https://github.com/LMNRY/SetProperty
    public Color backgroundColor=Color.white;
    public Color circleColor = Color.yellow;
    public float blurFactor = 2.0f;  //模糊因子,用来模糊圆形边界的
    
    #endregion

    private Texture2D generatedTexture = null;
    
    void Start()
    {
        if (material == null)
        {
            Renderer renderer = gameObject.GetComponent<Renderer>();
            if (renderer == null)
            {
                Debug.LogWarning("cannot find a renderer");
                return;
            }

            material = renderer.sharedMaterial;
        }    
        _UpdateMaterial();  //为material生成程序纹理
    }

    private void _UpdateMaterial()
    {
        if (material != null)
        {
            generatedTexture = _GenerateProcedureTexture();
            material.SetTexture("_MainTex", generatedTexture);
        }
    }

    private Texture2D _GenerateProcedureTexture()
    {
        Texture2D procedureTexture = new Texture2D(textureWidth, textureWidth);
        float circleInterval = textureWidth / 4.0f;
        float radius = textureWidth / 10.0f;
        float edgeBlur = 1.0f / blurFactor; //定义模糊系数

        for (int w = 0; w < textureWidth; w++)
        {
            for (int h = 0; h < textureWidth; h++)
            {
                Color pixel = backgroundColor;
                //依次画9个圆
                for (int i = 0; i < 3; i++)
                {
                    for (int j = 0; j < 3; j++)
                    {
                        //计算当前绘制的圆的圆心位置
                        Vector2 circleCenter = new Vector2(circleInterval * (i + 1), circleInterval * (j + 1));
                        //计算当前像素与圆心的距离
                        float dist = Vector2.Distance(new Vector2(w, h), circleCenter) - radius;
                        //模糊圆的边界
                        //关于SmoothStep函数的说明,可以看这篇博客:https://blog.csdn.net/woodengm/article/details/125597326
                        Color color = _MixColor(circleColor, new Color(pixel.r, pixel.g, pixel.b, 0.0f),
                            Mathf.SmoothStep(0f, 1.0f, dist * edgeBlur));
                        //依次计算9个圆对颜色的混合,每次会和之前得到的颜色进行混合
                        pixel = _MixColor(pixel, color, color.a); //color.a就是0-1之间通过(对dist * edgeBlur平滑后的结果)作为混合因子得到的值
                    }
                }
                procedureTexture.SetPixel(w,h,pixel);
            }
        }
        procedureTexture.Apply(); //强制把像素值写入纹理当中
        return procedureTexture;
    }
    
    //书上漏了一个函数,这里把它补上,一个简单的lerp操作做颜色混合.
    private Color _MixColor(Color color0, Color color1, float mixFactor) 
    {
        Color mixColor = Color.white;
        mixColor.r = Mathf.Lerp(color0.r, color1.r, mixFactor);
        mixColor.g = Mathf.Lerp(color0.g, color1.g, mixFactor);
        mixColor.b = Mathf.Lerp(color0.b, color1.b, mixFactor);
        mixColor.a = Mathf.Lerp(color0.a, color1.a, mixFactor);
        return mixColor;
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
