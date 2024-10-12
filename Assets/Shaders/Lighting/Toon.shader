/*
    References:
        https://roystan.net/articles/toon-shader/
        https://en.wikipedia.org/wiki/Blinn–Phong_reflection_model
*/
Shader "Lighting/Toon"
{
    Properties
    {
        [Header(Colours)][Space(10)]
        _DiffuseColour("Diffuse Colour", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        [Normal]_Normal("Normal", 2D) = "bump" {}
        _NormalStrength("Normal Strength", Range(0,20)) = 1

        [Header(Blinn Phong)][Space(10)]
        [Toggle(SPECULAR)] _Specular("Specular Highlight", float) = 1

        _k ("Coefficients (Ambient, Diffuse, Specular)", Vector) = (0.5,0.5,0.8)
        _SpecularExponent("Specular Exponent", Float) = 80

        [Header(Rim)][Space(10)]
        [Toggle(RIM)] _Rim("Rim", float) = 1
        _FresnelPower("Fresnel Power", Range(0.01, 1)) = 0.5
        _RimThreshold("Rim Threshold", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Pass
        {
            Name "ForwardBase"
            Tags
            {
                "LightMode"="ForwardBase"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma shader_feature RIM
            #pragma shader_feature SPECULAR


            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            uniform half4 _DiffuseColour;

            uniform sampler2D _MainTex;
            uniform half4 _MainTex_ST;

            uniform half4 _Normal_ST;
            uniform sampler2D _Normal;
            uniform half _NormalStrength;

            uniform half4 _LightColor0;
            uniform half3 _k;

            uniform float _SpecularExponent;
            uniform float _FresnelPower;
            uniform float _RimThreshold;

            struct appdata
            {
                half4 vertex: POSITION;
                half3 normal: NORMAL;
                half2 uv : TEXCOORD0;
                half4 tangent : TANGENT;
            };

            struct v2f
            {
                half4 pos: SV_POSITION;
                half2 uv_MainTex : TEXCOORD0;
                half2 uv_Normal : TEXCOORD1;
                half3 worldPos: TEXCOORD2;
                half3x3 TBN : TEXCOORD3;
                SHADOW_COORDS(6)
                UNITY_FOG_COORDS(7)
            };

            v2f vert(appdata vx)
            {
                v2f o;
                o.uv_MainTex = vx.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv_Normal = vx.uv * _Normal_ST.xy + _Normal_ST.zw;
                o.pos = UnityObjectToClipPos(vx.vertex);
                o.worldPos = mul(unity_ObjectToWorld, vx.vertex).xyz;

                half3 worldNormal = UnityObjectToWorldNormal(vx.normal);
                half3 worldTangent = mul((float3x3)unity_ObjectToWorld, vx.tangent);

                half3 bitangent = cross(worldNormal, worldTangent);
                half3 worldBitangent = mul((float3x3)unity_ObjectToWorld, bitangent);

                o.TBN = float3x3(worldTangent, worldBitangent, worldNormal);

                TRANSFER_SHADOW(o);
                UNITY_TRANSFER_FOG(o, o.pos);

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 c = tex2D(_MainTex, i.uv_MainTex) * _DiffuseColour;

                half3 normalMap = UnpackNormal(tex2D(_Normal, i.uv_Normal));
                normalMap.xy *= _NormalStrength;

                half3 n = normalize(mul(transpose(i.TBN), normalMap));
                // Transforming normal map vectors from tangent space to world space. TBN * v_world = v_tangent | TBN-1 * v_tangent = v_world
                half3 l = normalize(_WorldSpaceLightPos0.xyz);
                half3 v = normalize(_WorldSpaceCameraPos - i.worldPos);
                half3 h = normalize(l + v);

                fixed NdotL = saturate(dot(n, l));

                fixed shadow = SHADOW_ATTENUATION(i);
                float lightIntensity = NdotL * shadow * 1000.0;
                lightIntensity = saturate(lightIntensity);

                // Blinn-Phong
                fixed Ia = _k.x;
                fixed Id = _k.y * lightIntensity;

                #ifdef SPECULAR
                float Is = _k.z * pow(saturate(dot(h, n)), _SpecularExponent * _SpecularExponent);
                Is = smoothstep(0.005, 0.01, Is);
                #else
                float Is = 0.0;  // Disable specular if checkbox is unchecked
                #endif

                half3 skyboxColor = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, float3(0,1,0)).rgb;

                half3 ambient = Ia * (UNITY_LIGHTMODEL_AMBIENT + _LightColor0.rgb + skyboxColor);
                half3 diffuse = Id * _LightColor0.rgb * shadow;
                half3 specular = Is * _LightColor0.rgb * shadow;

                // Fresnel Rim-Lighting
                half4 fresnel;
                #ifdef RIM

                fixed rimDot = 1 - dot(v, n);
                float rimIntensity = rimDot * pow(NdotL, _RimThreshold);

                rimIntensity = smoothstep(_FresnelPower - 0.01, _FresnelPower + 0.01, rimIntensity);
                fresnel = rimIntensity * _LightColor0;

                #else
                fresnel = 0;
                #endif

                half3 lighting = diffuse + specular + fresnel;

                half3 finalColor = ambient + lighting;
                finalColor *= c.rgb;

                UNITY_APPLY_FOG(i.fogCoord, finalColor);

                return half4(finalColor, 1.0);
            }
            ENDHLSL

        }

        Pass
        {
            Name "ForwardAdd"
            Tags
            {
                "LightMode" = "ForwardAdd"
            }

            Blend One One

            HLSLPROGRAM
            #pragma vertex vertAdd
            #pragma fragment fragAdd
            #pragma multi_compile_fwdadd
            #pragma multi_compile_fog
            #pragma shader_feature RIM
            #pragma shader_feature SPECULAR


            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            uniform half4 _DiffuseColour;

            uniform sampler2D _MainTex;
            uniform half4 _MainTex_ST;

            uniform half4 _Normal_ST;
            uniform sampler2D _Normal;
            uniform half _NormalStrength;

            uniform half4 _LightColor0;
            uniform half3 _k;

            uniform float _SpecularExponent;
            uniform float _FresnelPower;
            uniform float _RimThreshold;

            struct appdata
            {
                half4 vertex: POSITION;
                half3 normal: NORMAL;
                half2 uv : TEXCOORD0;
                half4 tangent : TANGENT;
            };

            struct v2f
            {
                half4 pos: SV_POSITION;
                half2 uv_MainTex : TEXCOORD0;
                half2 uv_Normal : TEXCOORD1;
                half3 worldPos: TEXCOORD2;
                half3x3 TBN : TEXCOORD3;
                SHADOW_COORDS(6)
                UNITY_FOG_COORDS(7)
            };

            v2f vertAdd(appdata vx)
            {
                v2f o;
                o.uv_MainTex = vx.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv_Normal = vx.uv * _Normal_ST.xy + _Normal_ST.zw;
                o.pos = UnityObjectToClipPos(vx.vertex);
                o.worldPos = mul(unity_ObjectToWorld, vx.vertex).xyz;

                half3 worldNormal = UnityObjectToWorldNormal(vx.normal);
                half3 worldTangent = mul((float3x3)unity_ObjectToWorld, vx.tangent);

                half3 bitangent = cross(worldNormal, worldTangent);
                half3 worldBitangent = mul((float3x3)unity_ObjectToWorld, bitangent);

                o.TBN = float3x3(worldTangent, worldBitangent, worldNormal);

                TRANSFER_SHADOW(o);
                UNITY_TRANSFER_FOG(o, o.pos);

                return o;
            }

            half4 fragAdd(v2f i) : SV_Target
            {
                half4 c = tex2D(_MainTex, i.uv_MainTex) * _DiffuseColour;

                half3 normalMap = UnpackNormal(tex2D(_Normal, i.uv_Normal));
                normalMap.xy *= _NormalStrength;

                half3 l;
                half atten;

                if (_WorldSpaceLightPos0.w == 0.0)
                {
                    // Directional light
                    l = normalize(_WorldSpaceLightPos0.xyz);
                    atten = 1.0;
                }
                else
                {
                    // Point light
                    float3 lightPosWorld = _WorldSpaceLightPos0.xyz;
                    l = lightPosWorld - i.worldPos;
                    float distanceSqr = dot(l, l);
                    l = normalize(l);

                    // Calculate attenuation
                    float range = _LightColor0.w; // Light range is stored in w component
                    atten = saturate(1.0 - sqrt(distanceSqr) / range);
                }

                half3 n = normalize(mul(transpose(i.TBN), normalMap));
                // Transforming normal map vectors from tangent space to world space. TBN * v_world = v_tangent | TBN-1 * v_tangent = v_world
                half3 v = normalize(_WorldSpaceCameraPos - i.worldPos);
                half3 h = normalize(l + v);

                fixed NdotL = saturate(dot(n, l)) * atten;

                fixed shadow = SHADOW_ATTENUATION(i);
                float lightIntensity = NdotL * shadow * 1000.0;
                lightIntensity = saturate(lightIntensity);

                // Blinn-Phong
                fixed Id = _k.y * lightIntensity;

                #ifdef SPECULAR
                float Is = _k.z * pow(saturate(dot(h, n)), _SpecularExponent * _SpecularExponent);
                Is = smoothstep(0.005, 0.01, Is);
                #else
                float Is = 0.0;  // Disable specular if checkbox is unchecked
                #endif

                half3 skyboxColor = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, float3(0,1,0)).rgb;

                half3 diffuse = Id * _LightColor0.rgb * shadow;
                half3 specular = Is * _LightColor0.rgb * shadow;

                // Fresnel Rim-Lighting
                half4 fresnel;
                #ifdef RIM

                fixed rimDot = 1 - dot(v, n);
                float rimIntensity = rimDot * pow(NdotL, _RimThreshold);

                rimIntensity = smoothstep(_FresnelPower - 0.01, _FresnelPower + 0.01, rimIntensity);
                fresnel = rimIntensity * _LightColor0;

                #else
                fresnel = 0;
                #endif

                half3 lighting = diffuse + specular + fresnel;

                half3 finalColor = lighting;
                finalColor *= c.rgb;

                UNITY_APPLY_FOG(i.fogCoord, finalColor);

                return half4(finalColor, 1.0);
            }
            ENDHLSL

        }
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }


}