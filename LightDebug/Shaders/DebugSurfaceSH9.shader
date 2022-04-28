Shader "Xlwnya/Debug/SurfSH9"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 200

        // ------------------------------------------------------------
        // Surface shader code generated out of a CGPROGRAM block:

        // ---- forward rendering base pass:
        Pass
        {
            Name "FORWARD"
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM
            // compile directives
            #pragma vertex vert_surf
            #pragma fragment frag_surf
            #pragma target 3.0
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase
            #include "HLSLSupport.cginc"
            #define UNITY_INSTANCED_LOD_FADE
            #define UNITY_INSTANCED_SH
            #define UNITY_INSTANCED_LIGHTMAPSTS
            #include "UnityShaderVariables.cginc"
            #include "UnityShaderUtilities.cginc"
            // -------- variant for: <when no other keywords are defined>

            // -------- variant for: INSTANCING_ON 
            // Surface shader code generated based on:
            // writes to per-pixel normal: no
            // writes to emission: no
            // writes to occlusion: no
            // needs world space reflection vector: no
            // needs world space normal vector: no
            // needs screen space position: no
            // needs world space position: no
            // needs view direction: no
            // needs world space view direction: no
            // needs world space position for lighting: YES
            // needs world space view direction for lighting: YES
            // needs world space view direction for lightmaps: no
            // needs vertex color: no
            // needs VFACE: no
            // passes tangent-to-world matrix to pixel shader: no
            // reads from normal: no
            // 0 texcoords actually used
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"

            #define INTERNAL_DATA
            #define WorldReflectionVector(data,normal) data.worldRefl
            #define WorldNormalVector(data,normal) normal

            // Original surface shader snippet:
            #line 12 ""
            #ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
            #endif
            /* UNITY: Original start of shader */
            // Physically based Standard lighting model, and enable shadows on all light types
            //#pragma surface surf Standard fullforwardshadows

            // Use shader model 3.0 target, to get nicer looking lighting
            //#pragma target 3.0

            struct Input
            {
                float2 uv_MainTex;
            };

            float _Glossiness;
            float _Metallic;
            float4 _Color;

            void surf(Input IN, inout SurfaceOutputStandard o)
            {
                o.Albedo = _Color.rgb;
                o.Metallic = _Metallic;
                o.Smoothness = _Glossiness;
                o.Alpha = 1.0;
            }

            // vertex-to-fragment interpolation data
            // no lightmaps:
            struct v2f_surf
            {
                UNITY_POSITION(pos);
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                #if UNITY_SHOULD_SAMPLE_SH
                    half3 sh : TEXCOORD2; // SH
                #endif
                UNITY_FOG_COORDS(3)
                UNITY_SHADOW_COORDS(4)
                #if SHADER_TARGET >= 30
                    float4 lmap : TEXCOORD5;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // vertex shader
            v2f_surf vert_surf(appdata_full v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                v2f_surf o;
                UNITY_INITIALIZE_OUTPUT(v2f_surf, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = UnityObjectToClipPos(v.vertex);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                
                o.worldPos.xyz = worldPos;
                o.worldNormal = worldNormal;

                // SH/ambient and vertex lights
                #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
                  o.sh = 0;
                  // Approximated illumination from non-important point lights
                #ifdef VERTEXLIGHT_ON
                    //o.sh += Shade4PointLights (
                    //    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                    //    unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                    //    unity_4LightAtten0, worldPos, worldNormal);
                #endif
                    o.sh = ShadeSHPerVertex (worldNormal, o.sh);
                #endif

                UNITY_TRANSFER_LIGHTING(o, v.texcoord1.xy);
                return o;
            }

            // fragment shader
            fixed4 frag_surf(v2f_surf IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                // prepare and unpack data
                Input surfIN;
                UNITY_INITIALIZE_OUTPUT(Input, surfIN);
                surfIN.uv_MainTex.x = 1.0;
                float3 worldPos = IN.worldPos.xyz;
                #ifndef USING_DIRECTIONAL_LIGHT
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                #else
                    fixed3 lightDir = _WorldSpaceLightPos0.xyz;
                #endif
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                #ifdef UNITY_COMPILER_HLSL
                    SurfaceOutputStandard o = (SurfaceOutputStandard)0;
                #else
                    SurfaceOutputStandard o;
                #endif
                o.Albedo = 0.0;
                o.Emission = 0.0;
                o.Alpha = 0.0;
                o.Occlusion = 1.0;
                fixed3 normalWorldVertex = fixed3(0, 0, 1);
                o.Normal = IN.worldNormal;
                normalWorldVertex = IN.worldNormal;

                // call surface function
                surf(surfIN, o);

                // compute lighting & shadowing factor
                UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
                fixed4 c = 0;

                // Setup lighting environment
                UnityGI gi;
                UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
                gi.indirect.diffuse = 0;
                gi.indirect.specular = 0;
                gi.light.color = float3(0, 0, 0);
                gi.light.dir = half3(0, -1, 0);
                // Call GI (lightmaps/SH/reflections) lighting function
                UnityGIInput giInput;
                UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
                giInput.light = gi.light;
                giInput.worldPos = worldPos;
                giInput.worldViewDir = worldViewDir;
                giInput.atten = 0.0;
                giInput.lightmapUV = 0.0;
                #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
                    giInput.ambient = IN.sh;
                #else
                giInput.ambient.rgb = 0.0;
                #endif
                LightingStandard_GI(o, giInput, gi);
                gi.indirect.specular = 0;
                
                // realtime lighting: call lighting function
                c += LightingStandard(o, worldViewDir, gi);
                UNITY_OPAQUE_ALPHA(c.a);
                return c;
            }
            ENDCG

        }

        // ---- forward rendering additive lights pass:
        Pass
        {
            Name "FORWARD"
            Tags
            {
                "LightMode" = "ForwardAdd"
            }
            ZWrite Off Blend One One

            CGPROGRAM
            // compile directives
            #pragma vertex vert_surf
            #pragma fragment frag_surf
            #pragma target 3.0
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            #pragma multi_compile_fwdadd_fullshadows
            #include "HLSLSupport.cginc"
            #define UNITY_INSTANCED_LOD_FADE
            #define UNITY_INSTANCED_SH
            #define UNITY_INSTANCED_LIGHTMAPSTS
            #include "UnityShaderVariables.cginc"
            #include "UnityShaderUtilities.cginc"
            // -------- variant for: <when no other keywords are defined>
            // Surface shader code generated based on:
            // writes to per-pixel normal: no
            // writes to emission: no
            // writes to occlusion: no
            // needs world space reflection vector: no
            // needs world space normal vector: no
            // needs screen space position: no
            // needs world space position: no
            // needs view direction: no
            // needs world space view direction: no
            // needs world space position for lighting: YES
            // needs world space view direction for lighting: YES
            // needs world space view direction for lightmaps: no
            // needs vertex color: no
            // needs VFACE: no
            // passes tangent-to-world matrix to pixel shader: no
            // reads from normal: no
            // 0 texcoords actually used
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"

            #define INTERNAL_DATA
            #define WorldReflectionVector(data,normal) data.worldRefl
            #define WorldNormalVector(data,normal) normal

            // Original surface shader snippet:
            #line 12 ""
            #ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
            #endif
            /* UNITY: Original start of shader */
            // Physically based Standard lighting model, and enable shadows on all light types
            //#pragma surface surf Standard fullforwardshadows

            // Use shader model 3.0 target, to get nicer looking lighting
            //#pragma target 3.0

            struct Input
            {
                float2 uv_MainTex;
            };

            float _Glossiness;
            float _Metallic;
            float4 _Color;

            void surf(Input IN, inout SurfaceOutputStandard o)
            {
                o.Albedo = _Color.rgb;
                o.Metallic = _Metallic;
                o.Smoothness = _Glossiness;
                o.Alpha = 1.0;
            }


            // vertex-to-fragment interpolation data
            struct v2f_surf
            {
                UNITY_POSITION(pos);
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                UNITY_LIGHTING_COORDS(2, 3)
                UNITY_FOG_COORDS(4)
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // vertex shader
            v2f_surf vert_surf(appdata_full v)
            {
                return (v2f_surf)0;
            }

            // fragment shader
            fixed4 frag_surf(v2f_surf IN) : SV_Target
            {
                return fixed4(0, 0, 0, 0);
            }

            ENDCG

        }

        // ---- end of surface shader generated code

        #LINE 37

    }
    FallBack "Diffuse"
}