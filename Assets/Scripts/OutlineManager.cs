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

    [SerializeField] [Range(0,2)]private float edgeThickness = 1;
    [SerializeField] [Range(1,5)] private float edgeIntensity = 1;
    [SerializeField] private Color edgeColor;
    [SerializeField] [Range(0, 1)] private float normalThreshold = 0.2f;
    [SerializeField] [Range(0, 1)] private float depthThreshold = 0.0f;

    private void Start()
    {
        Camera.main.depthTextureMode = DepthTextureMode.DepthNormals;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material == null)
            material = new Material(shader);

        material.SetFloat("_EdgeThickness", edgeThickness);
        material.SetFloat("_EdgeIntensity", edgeIntensity);
        material.SetColor("_EdgeColor", edgeColor);
        material.SetFloat("_NormalThreshold", normalThreshold);
        material.SetFloat("_DepthThreshold", depthThreshold);


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