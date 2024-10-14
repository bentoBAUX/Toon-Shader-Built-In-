using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public enum RenderMode
{
    None = 0,
    Depth = 1,
    Normals = 2,
    DepthNormals = 3
}

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class DepthNormalsManager : MonoBehaviour
{
    [SerializeField] private Shader shader;

    private Material material;

    [SerializeField] private RenderMode mode = RenderMode.Depth;


    private void Start()
    {
        Camera.main.depthTextureMode = DepthTextureMode.DepthNormals;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material == null)
            material = new Material(shader);
        switch (mode)
        {
            case RenderMode.None:
                material.DisableKeyword("DEPTH");
                material.DisableKeyword("NORMALS");
                material.DisableKeyword("DEPTHNORMALS");
                break;
            case RenderMode.Depth:
                material.EnableKeyword("DEPTH");
                material.DisableKeyword("NORMALS");
                material.DisableKeyword("DEPTHNORMALS");
                break;
            case RenderMode.Normals:
                material.DisableKeyword("DEPTH");
                material.EnableKeyword("NORMALS");
                material.DisableKeyword("DEPTHNORMALS");
                break;
            case RenderMode.DepthNormals:
                material.DisableKeyword("DEPTH");
                material.DisableKeyword("NORMALS");
                material.EnableKeyword("DEPTHNORMALS");
                break;
        }
        Graphics.Blit(source, destination, material);
    }

}