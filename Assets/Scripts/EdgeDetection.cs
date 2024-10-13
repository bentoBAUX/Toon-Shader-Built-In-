using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class EdgeDetection : MonoBehaviour
{
    [SerializeField] private Shader shader;
    [Range(0, 1)][SerializeField] private float offset;
    [Range(0, 1)][SerializeField] private float threshold;

    private Material material;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material == null)
            material = new Material(shader);

        material.SetFloat("_Threshold", threshold);
        material.SetFloat("_Offset", offset);

        Graphics.Blit(source, destination, material);
    }
}
