using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public enum RenderMode
{
    Depth = 0,
    Normals = 1,
    DepthNormals = 2
}

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class DepthNormalsManager : MonoBehaviour
{
    [SerializeField] private Shader shader;

    private Material material;

    [SerializeField] private RenderMode mode = RenderMode.Depth;


    private void UpdateCameraDepthMode()
    {
        switch (mode)
        {
            case RenderMode.Depth:
                Camera.main.depthTextureMode = DepthTextureMode.Depth;
                break;
            case RenderMode.Normals:
                Camera.main.depthTextureMode = DepthTextureMode.DepthNormals;
                break;
            case RenderMode.DepthNormals:
                Camera.main.depthTextureMode = DepthTextureMode.DepthNormals;
                break;
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material == null)
            material = new Material(shader);
        switch (mode)
        {
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

    private void OnValidate()
    {
        UpdateCameraDepthMode();
    }

}