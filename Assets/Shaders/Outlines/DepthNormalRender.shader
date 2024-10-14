Shader "Image Effects/DepthNormals"
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
            CGPROGRAM
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
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthNormalsTexture);

            fixed4 frag(v2f i) : SV_Target
            {
                float depth;
                float3 normals;

                float4 col = tex2D(_MainTex, i.uv); // Fallback color (red)

                #ifdef DEPTH
                depth = tex2D(_CameraDepthTexture, i.scrPos.xy).r;
                float linearDepth = Linear01Depth(depth);
                linearDepth = saturate(linearDepth * 100);
                col = float4(linearDepth, linearDepth, linearDepth, 1);
                #endif

                #ifdef NORMALS
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.scrPos.xy), depth, normals);
                col = float4(normals.xyz * 0.5 + 0.5, 1); // Map normals to [0, 1] range
                #endif

                #ifdef DEPTHNORMALS
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.scrPos.xy), depth, normals);
                col = float4(normals.xyz, 1); // Display normals without remapping
                #endif

                return col;
            }
            ENDCG
        }
    }
}