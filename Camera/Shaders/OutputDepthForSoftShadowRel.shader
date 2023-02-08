Shader "Xlwnya/OutputDepthForSoftShadowRel"
{
    Properties
    {
        [Toggle] _TargetOnly("Target Camera only", Int) = 1
        _BlurOffset ("BlurOffset", Float) = 1
        [KeywordEnum(Gauss5, Gauss3, None)]_BLUR_MODE("Blur Mode", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Overlay" }
        LOD 100

        Pass
        {
            ZWrite Off
            ZTest Always

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing

            #pragma shader_feature_local _BLUR_MODE_GAUSS5 _BLUR_MODE_GAUSS3 _BLUR_MODE_NONE

            #include "UnityCG.cginc"

            float3 _TargetCameraPos;
            int _TargetOnly;
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            float _BlurOffset;

            static float gaussian5[] = {
                1.0,  4.0,  6.0,  4.0, 1.0,
                4.0, 16.0, 24.0, 16.0, 4.0,
                6.0, 24.0, 36.0, 24.0, 6.0,
                4.0, 16.0, 24.0, 16.0, 4.0,
                1.0,  4.0,  6.0,  4.0, 1.0
            };
            static int gaussian5_sum = 256;
            static int gaussian5_size = 25;
            
            static float gaussian3[] = {
                1.0, 2.0, 1.0,
                2.0, 4.0, 2.0,
                1.0, 2.0, 1.0
            };
            static int gaussian3_sum = 16;
            static int gaussian3_size = 9;

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screen_pos : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(const appdata_base v)
            {
                v2f o;
                //UNITY_INITIALIZE_OUTPUT(v2g, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                const float3 worldObjectPos = mul(unity_ObjectToWorld, float4(0.0, 0.0, 0.0, 1.0)).xyz;
                // 特定のカメラ以外で処理を停止する
                if (_TargetOnly && 0.01 < distance(worldObjectPos, _WorldSpaceCameraPos)) {
                    return (v2f)0;
                }

                float2 xy = v.texcoord*2 - 1; 
                o.vertex = mul(UNITY_MATRIX_P, float4(xy, - (_ProjectionParams.y + _ProjectionParams.z)/2, 1));
                o.vertex.xy = xy * o.vertex.w;
                o.vertex.y *= _ProjectionParams.x;

                o.uv = v.texcoord;
                o.screen_pos = ComputeScreenPos(o.vertex);

                return o;
            }

            // https://forum.unity.com/threads/getting-scene-depth-z-buffer-of-the-orthographic-camera.601825/#post-4966334
            inline float Correct01Depth(float rawDepth)
            {
                float orthoDepth = rawDepth;
                #if defined(UNITY_REVERSED_Z)
                    orthoDepth = 1 - orthoDepth;
                #endif
                return lerp(Linear01Depth(rawDepth), orthoDepth, unity_OrthoParams.w);
            }
            
            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                // Depth
                float2 pixelSize = 1.0 / _ScreenParams.xy * _BlurOffset;

                float2 depth = float2(0, 0); // depth, depthSq

                #if defined(_BLUR_MODE_NONE)
                    float d = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, i.screen_pos);
                    d = Correct01Depth(d);
                    depth += float2(d, d*d);
                #elif defined(_BLUR_MODE_GAUSS5)
                    UNITY_UNROLL
                    for (int index = 0; index < gaussian5_size; index++)
                    {
                        float x = index % 5 - 2;
                        float y = index / 5 - 2;
                        float4 offsetPos = float4(i.screen_pos.xy+pixelSize*float2(x, y), i.screen_pos.zw);
                        float d = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, offsetPos);
                        d = Correct01Depth(d);
                        depth += float2(d, d*d) * gaussian5[index];
                    }
                    depth /= gaussian5_sum;
                #elif defined(_BLUR_MODE_GAUSS3)
                    UNITY_UNROLL
                    for (int index = 0; index < gaussian3_size; index++)
                    {
                        float x = index % 3 - 1;
                        float y = index / 3 - 1;
                        float4 offsetPos = float4(i.screen_pos.xy+pixelSize*float2(x, y), i.screen_pos.zw);
                        float d = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, offsetPos);
                        d = Correct01Depth(d);
                        depth += float2(d, d*d) * gaussian3[index];
                    }
                    depth /= gaussian3_sum;
                #endif

                return float4(depth, 1, 1);
            }
            ENDCG
        }
    }
}
