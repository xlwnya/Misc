﻿Shader "Xlwnya/ManualShadow/CalcSoftShadowDepth"
{
    Properties
    {
        _DepthTex ("DepthTex", 2D) = "white" {}
        _BlurOffset ("BlurOffset", Float) = 1
        [KeywordEnum(Gauss5, Gauss3, Gauss7, None)]_BLUR_MODE("Blur Mode", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing

            #pragma shader_feature_local _BLUR_MODE_GAUSS7 _BLUR_MODE_GAUSS5 _BLUR_MODE_GAUSS3 _BLUR_MODE_NONE

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D_float _DepthTex;
            float4 _DepthTex_ST;
            float4 _DepthTex_TexelSize;

            float _BlurOffset;
            
            static float gaussian7[] = { 1.0, 6.0, 15.0, 20.0, 15.0, 6.0, 1.0 };
            static int gaussian7_sum = 64;
            static int gaussian7_size = 7;
            
            static float gaussian5[] = { 1.0,  4.0,  6.0,  4.0, 1.0 };
            static int gaussian5_sum = 16;
            static int gaussian5_size = 5;
            
            static float gaussian3[] = { 1.0, 2.0, 1.0 };
            static int gaussian3_sum = 4;
            static int gaussian3_size = 3;
            
            // https://forum.unity.com/threads/getting-scene-depth-z-buffer-of-the-orthographic-camera.601825/#post-4966334
            inline float Correct01Depth(float rawDepth)
            {
                // 一回テクスチャに出力されている場合depthがどうなっているか謎のため平行投影以外の場合動くか不明
                #if defined(UNITY_REVERSED_Z)
                    return 1 - rawDepth;
                #else
                    return rawDepth;
                #endif
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                //UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _DepthTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // Depth
                float2 pixelSize = _DepthTex_TexelSize.xy * _BlurOffset;

                float2 depth = float2(0, 0); // depth, depthSq
                
                #if defined(_BLUR_MODE_NONE)
                    float d = tex2Dlod(_DepthTex, float4(i.uv, 0, 0)).r;
                    d = Correct01Depth(d);
                    depth += float2(d, d*d);
                #elif defined(_BLUR_MODE_GAUSS7)
                    UNITY_UNROLL
                    for (int index = 0; index < gaussian7_size; index++)
                    {
                        float x = index - 3;
                        float4 offsetPos = float4(i.uv.xy+pixelSize*float2(x, 0), 0, 0);
                        float d = tex2Dlod(_DepthTex, offsetPos).r;
                        d = Correct01Depth(d);
                        depth += float2(d, d*d) * gaussian7[index];
                    }
                    depth /= gaussian7_sum;
                #elif defined(_BLUR_MODE_GAUSS5)
                    UNITY_UNROLL
                    for (int index = 0; index < gaussian5_size; index++)
                    {
                        float x = index - 2;
                        float4 offsetPos = float4(i.uv.xy+pixelSize*float2(x, 0), 0, 0);
                        float d = tex2Dlod(_DepthTex, offsetPos).r;
                        d = Correct01Depth(d);
                        depth += float2(d, d*d) * gaussian5[index];
                    }
                    depth /= gaussian5_sum;
                #elif defined(_BLUR_MODE_GAUSS3)
                    UNITY_UNROLL
                    for (int index = 0; index < gaussian3_size; index++)
                    {
                        float x = index - 1;
                        float4 offsetPos = float4(i.uv.xy+pixelSize*float2(x, 0), 0, 0);
                        float d = tex2Dlod(_DepthTex, offsetPos).r;
                        d = Correct01Depth(d);
                        depth += float2(d, d*d) * gaussian3[index];
                    }
                    depth /= gaussian3_sum;
                #endif

                return float4(depth, 1, 1);
            }
            ENDCG
        }
        
        GrabPass { }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing

            #pragma shader_feature_local _BLUR_MODE_GAUSS7 _BLUR_MODE_GAUSS5 _BLUR_MODE_GAUSS3 _BLUR_MODE_NONE

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D_float _GrabTexture;
            float4 _GrabTexture_ST;
            float4 _GrabTexture_TexelSize;

            float _BlurOffset;
            
            static float gaussian7[] = { 1.0, 6.0, 15.0, 20.0, 15.0, 6.0, 1.0 };
            static int gaussian7_sum = 64;
            static int gaussian7_size = 7;
            
            static float gaussian5[] = { 1.0,  4.0,  6.0,  4.0, 1.0 };
            static int gaussian5_sum = 16;
            static int gaussian5_size = 5;
            
            static float gaussian3[] = { 1.0, 2.0, 1.0 };
            static int gaussian3_sum = 4;
            static int gaussian3_size = 3;
            
            v2f vert (appdata v)
            {
                v2f o;
                //UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _GrabTexture);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // Depth
                float2 pixelSize = _GrabTexture_TexelSize.xy * _BlurOffset;

                float2 depth = float2(0, 0); // depth, depthSq
                
                #if defined(_BLUR_MODE_NONE)
                    float2 d = tex2Dlod(_GrabTexture, float4(i.uv, 0, 0)).rg;
                    depth += d;
                #elif defined(_BLUR_MODE_GAUSS7)
                    UNITY_UNROLL
                    for (int index = 0; index < gaussian7_size; index++)
                    {
                        float y = index - 3;
                        float4 offsetPos = float4(i.uv.xy+pixelSize*float2(0, y), 0, 0);
                        float2 d = tex2Dlod(_GrabTexture, offsetPos).rg;
                        depth += d * gaussian7[index];
                    }
                    depth /= gaussian7_sum;
                #elif defined(_BLUR_MODE_GAUSS5)
                    UNITY_UNROLL
                    for (int index = 0; index < gaussian5_size; index++)
                    {
                        float y = index - 2;
                        float4 offsetPos = float4(i.uv.xy+pixelSize*float2(0, y), 0, 0);
                        float2 d = tex2Dlod(_GrabTexture, offsetPos).rg;
                        depth += d * gaussian5[index];
                    }
                    depth /= gaussian5_sum;
                #elif defined(_BLUR_MODE_GAUSS3)
                    UNITY_UNROLL
                    for (int index = 0; index < gaussian3_size; index++)
                    {
                        float y = index - 1;
                        float4 offsetPos = float4(i.uv.xy+pixelSize*float2(0, y), 0, 0);
                        float2 d = tex2Dlod(_GrabTexture, offsetPos).rg;
                        depth += d * gaussian3[index];
                    }
                    depth /= gaussian3_sum;
                #endif

                return float4(depth, 1, 1);
            }
            ENDCG
        }
    }
}
