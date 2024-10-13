Shader "Hidden/SobelMatrix"
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
            };

            static const float SobelFilterKernelH[9] =
            {
                -1, 0, 1,
                -2, 0, 2,
                -1, 0, 1
            };

            static const float SobelFilterKernelV[9] =
            {
                -1, -2, -1,
                 0,  0,  0,
                 1,  2,  1
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;

            float4 SobelFilter(sampler2D tex, float2 texCoord, float2 texelSize)
            {
                float4 sumHorizontal = float4(0, 0, 0, 1);
                float4 sumVertical   = float4(0, 0, 0, 1);
                float2 coordinate;
                int    count = 0;

                for (int x = -1; x <= 1; x++)
                {
                    for (int y = -1; y <= 1; y++)
                    {
                        coordinate = float2(texCoord.x + texelSize.x * x, texCoord.y + texelSize.y * y);
                        sumHorizontal.rgb += tex2D(tex, coordinate).rgb * SobelFilterKernelH[count];
                        sumVertical.rgb   += tex2D(tex, coordinate).rgb * SobelFilterKernelV[count];
                        count++;
                    }
                }

                return sqrt(sumHorizontal * sumHorizontal + sumVertical * sumVertical);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return tex2D(_MainTex, i.uv) - SobelFilter(_MainTex, i.uv, _MainTex_TexelSize.xy);
            }
            ENDCG
        }
    }
}
