// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Forward Shadows Shader"
{
    Properties
    {
        _Color ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Diffuse (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Geometry" "RenderType" = "Opaque" "IgnoreProjector" = "True"
        }

        Pass
        {
            // Need to have it know it's to be used as a forward base pass.
            Tags
            {
                "LightMode" = "ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // Need to have it know it's compiling it as forward base pass.
            #pragma multi_compile_fwdbase
            #pragma fragmentoption ARB_precision_hint_fastest

            #include "UnityCG.cginc"
            // This includes the required macros for shadow and attenuation values.
            #include "AutoLight.cginc"

            struct appdata
            {
                half4 vertex: POSITION;
                half3 normal: NORMAL;
                half2 uv : TEXCOORD0;
                half4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 lightDir : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
                LIGHTING_COORDS(4, 5)
                // This fills the TEXCOORD of the given numbers - TEXCOORD3 and TEXCOORD4 in this case - with the values required for the vertex shader to send to the fragment shader.
            };

            float4 _MainTex_ST;
            float3 _Color;

            v2f vert(appdata v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex).xy;
                o.normal = v.normal.xyz;
                o.viewDir = ObjSpaceViewDir(v.vertex).xyz;
                o.lightDir = ObjSpaceLightDir(v.vertex).xyz;
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                // This lets the fragment shader calculate the the attenuation + shadow value.
                return o;
            }

            sampler2D _MainTex;
            fixed4 _LightColor0;

            fixed4 frag(v2f i) : COLOR
            {
                fixed atten = LIGHT_ATTENUATION(i); // This gets you the attenuation + shadow value.
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                fixed NdotL = saturate(dot(i.normal, i.lightDir));
                fixed4 c;
                c.rgb = (UNITY_LIGHTMODEL_AMBIENT.rgb * albedo) * UNITY_LIGHTMODEL_AMBIENT * 2;
                c.rgb += (NdotL * atten * 2) * (_LightColor0.rgb * albedo);
                c.a = 1.0;
                return c;
            }
            ENDCG
        }

        Pass
        {
            // Need to have it know it's to be used as a forward add pass.
            Tags
            {
                "LightMode" = "ForwardAdd"
            }
            // And it's additive to the base pass.
            Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // Need to have it know it's compiling it as forward add pass.
            // Alternatively, you can uncomment the line below and uncomment the line below that to tell it that the forward add pass should have shadows calculated rather than just attenuation.
            #pragma multi_compile_fwdadd
            // #pragma multi_compile_fwdadd_fullshadows
            #pragma fragmentoption ARB_precision_hint_fastest

            #include "UnityCG.cginc"
            // This includes the required macros for shadow and attenuation values.
            #include "AutoLight.cginc"

            float4 _MainTex_ST;

            struct appdata
            {
                half4 vertex: POSITION;
                half3 normal: NORMAL;
                half2 uv : TEXCOORD0;
                half4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 lightDir : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
                LIGHTING_COORDS(4, 5)
                // This fills the TEXCOORD of the given numbers - TEXCOORD3 and TEXCOORD4 in this case - with the values required for the vertex shader to send to the fragment shader.
            };

            v2f vert(appdata v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex).xy;
                o.normal = v.normal.xyz;
                o.viewDir = ObjSpaceViewDir(v.vertex).xyz;
                o.lightDir = ObjSpaceLightDir(v.vertex).xyz;
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                // This lets the fragment shader calculate the the attenuation + shadow value.
                return o;
            }

            sampler2D _MainTex;
            fixed4 _LightColor0;

            fixed4 frag(v2f i) : COLOR
            {
                fixed atten = LIGHT_ATTENUATION(i); // This gets you the attenuation + shadow value.
                fixed4 c;
                c.rgb = (saturate(dot(i.normal, i.lightDir)) * atten * 2) * (_LightColor0.rgb * tex2D(_MainTex, i.uv).
                    rgb);
                c.a = 1.0;
                return c;
            }
            ENDCG
        }
    }
    // Must have some fallback here that (eventually, from fallbacks of fallbacks) contains a shadow caster and reciever pass if you want shadows.
    // Alternatuvely you can just throw in your own shadow caster/reciever passes at the end of the subshader.
    //Fallback "Mobile/VertexLit"
}