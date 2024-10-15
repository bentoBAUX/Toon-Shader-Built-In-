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

                return sqrt(dot(g1, g1) + dot(g2, g2)) * _EdgeIntensity * 10; // Scale up for stronger edge detection
            }

            // Function to calculate normals gradient (difference in normals between neighbouring pixels)
            float EdgeDetectionNormals(float2 uv, float2 texelSize)
            {
                texelSize *= _EdgeThickness;

                float depth;
                float3 current, bottomRight, right, bottom;

                // Decode depth and normals for the current pixel and its neighbors
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uv), depth, current);
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uv + texelSize), depth, bottomRight);
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uv + float2(texelSize.x, 0)), depth, right);
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uv + float2(0, texelSize.y)), depth, bottom);

                // Compute gradient differences for normals
                float4 g1 = tex2D(_CameraDepthNormalsTexture, current) - tex2D(_CameraDepthNormalsTexture, bottomRight);
                float4 g2 = tex2D(_CameraDepthNormalsTexture, right) - tex2D(_CameraDepthNormalsTexture, bottom);

                return sqrt(dot(g1, g1) + dot(g2, g2)) * _EdgeIntensity * 10; // Scale up for stronger edge detection
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


                return lerp(originalColor, float4(0, 0, 0, 0), edge);
            }
            ENDHLSL
        }
    }
}