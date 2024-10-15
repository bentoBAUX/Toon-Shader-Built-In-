Shader "Image Effects/DepthNormalOutline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ DEPTH NORMALS DEPTHNORMALS


            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 scrPos : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.scrPos = ComputeScreenPos(o.vertex);
                return o;
            }

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float4 _MainTex_TexelSize;

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthNormalsTexture);

            uniform float _EdgeThickness;
            uniform float _EdgeIntensity;
            uniform float _NormalThreshold;
            uniform float _DepthThreshold;

            // Roberts Cross Filter https://youtu.be/N6Aty5alTXM

            float EdgeDetectionDepth(float2 uv, float2 texelSize)
            {
                texelSize *= _EdgeThickness;

                float2 current = uv;
                float2 bottomRight = uv + texelSize;
                float2 right = uv + float2(texelSize.x, 0);
                float2 bottom = uv + float2(0, texelSize.y);

                float4 g1 = tex2D(_CameraDepthTexture, current) - tex2D(_CameraDepthTexture, bottomRight);
                float4 g2 = tex2D(_CameraDepthTexture, right) - tex2D(_CameraDepthTexture, bottom);

                float edge = sqrt(dot(g1, g1) + dot(g2, g2));

                if (edge < _DepthThreshold) edge = 0.0;

                return edge * _EdgeIntensity * 10; // Scale up for stronger edge detection
            }


            // Function to calculate normals gradient (difference in normals between neighbouring pixels)
            float EdgeDetectionNormals(float2 uv, float2 texelSize)
            {
                texelSize *= _EdgeThickness;

                float depthCurrent, depthBottomRight, depthRight, depthBottom;
                float3 normalCurrent, normalBottomRight, normalRight, normalBottom;

                // Decode depth and normals for the current pixel and its neighbors
                float4 packedCurrent = tex2D(_CameraDepthNormalsTexture, uv);
                DecodeDepthNormal(packedCurrent, depthCurrent, normalCurrent);

                float4 packedBottomRight = tex2D(_CameraDepthNormalsTexture, uv + texelSize);
                DecodeDepthNormal(packedBottomRight, depthBottomRight, normalBottomRight);

                float4 packedRight = tex2D(_CameraDepthNormalsTexture, uv + float2(texelSize.x, 0));
                DecodeDepthNormal(packedRight, depthRight, normalRight);

                float4 packedBottom = tex2D(_CameraDepthNormalsTexture, uv + float2(0, texelSize.y));
                DecodeDepthNormal(packedBottom, depthBottom, normalBottom);

                float3 g1 = normalCurrent - normalBottomRight;
                float3 g2 = normalRight - normalBottom;

                float edge = sqrt(dot(g1, g1) + dot(g2, g2));

                if (edge < _NormalThreshold) edge = 0.0;

                return edge * _EdgeIntensity * 10;
            }

            float EdgeDetectionDepthNormals(float2 uv, float2 texelSize)
            {
                float depth = EdgeDetectionDepth(uv, texelSize);
                float normal = EdgeDetectionNormals(uv, texelSize);

                return max(depth,normal);
            }

            fixed4 frag(v2f i) : SV_Target
            {

                float edge = 0;

                float4 originalColor = tex2D(_MainTex, i.uv);
                float4 col = tex2D(_MainTex, i.uv); // Fallback color (default scene texture)



                #ifdef DEPTH
                edge = EdgeDetectionDepth(i.uv, _MainTex_TexelSize.xy);  // Detect edges based on depth
                col = float4(edge, edge, edge, 1);
                #endif

                #ifdef NORMALS
                edge = EdgeDetectionNormals(i.uv, _MainTex_TexelSize.xy);  // Detect edges based on normals
                col = float4(edge, edge, edge, 1);
                #endif

                #ifdef DEPTHNORMALS
                edge = EdgeDetectionDepthNormals(i.uv, _MainTex_TexelSize.xy);  // Detect edges based on normals
                col = float4(edge, edge, edge, 1);
                #endif


                return lerp(originalColor, float4(0, 0, 0, 0), edge);
            }
            ENDHLSL
        }
    }
}