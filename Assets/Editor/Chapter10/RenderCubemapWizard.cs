using UnityEngine;
using UnityEditor;
using System.Collections;

public class RenderCubemapWizard : ScriptableWizard {
	
    public Transform renderFromPosition;  //由用户指定,在该位置会生成一个摄像机
    public Cubemap cubemap;
	
    void OnWizardUpdate () {
        helpString = "choose transform to render from and cubemap to render";
        isValid = (renderFromPosition != null) && (cubemap != null);
    }
	
    void OnWizardCreate () {
        // create temporary camera for rendering
        GameObject go = new GameObject( "CubemapCamera");
        go.AddComponent<Camera>();
        // place it on the object
        go.transform.position = renderFromPosition.position;
        // render into cubemap		
        go.GetComponent<Camera>().RenderToCubemap(cubemap);  //摄像机调用该函数将图像渲染到指定的cubemap当中
		
        // destroy temporary camera
        DestroyImmediate( go );
    }
	
    [MenuItem("GameObject/Render into Cubemap")]
    static void RenderCubemap () {
        ScriptableWizard.DisplayWizard<RenderCubemapWizard>(
            "Render cubemap", "Render!");
    }
}