using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class OutlineManager : MonoBehaviour
{
    [SerializeField] private Shader shader;

    private Material material;

    [SerializeField] private Color OutlineColour;
    [SerializeField] [Range (5,10)]private float EdgeMultiplier = 1;
    [SerializeField] [Range (0,2)]private float EdgeThickness = 1;

    private void Start()
    {
        Camera.main.depthTextureMode = DepthTextureMode.DepthNormals;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material == null)
            material = new Material(shader);

        int ignoreLayer = LayerMask.NameToLayer("Lights");
        Camera.main.cullingMask &= ~(1 << ignoreLayer);

        material.SetColor("_OutlineColour", OutlineColour);
        material.SetFloat("_EdgeMultiplier", EdgeMultiplier);
        material.SetFloat("_EdgeThickness", EdgeThickness);

        Graphics.Blit(source, destination, material);
    }
}
