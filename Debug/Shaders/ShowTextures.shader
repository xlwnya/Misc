Shader "Xlwnya/ShowTextures"
{
    Properties
    {
        _MaxDepth ("Max depth", float) = 23
    }
    
    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "Queue" = "Transparent+500"
        }
        //LOD 100

        GrabPass { }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #pragma multi_compile_instancing

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
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // Grab
            UNITY_DECLARE_SCREENSPACE_TEXTURE(_GrabTexture);

            // デプスバッファ/Zバッファ
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            //UNITY_DECLARE_DEPTH_TEXTURE(_LastCameraDepthTexture);

            // DepthNormals
            UNITY_DECLARE_SCREENSPACE_TEXTURE(_CameraDepthNormalsTexture);

            // MotionVectors
            UNITY_DECLARE_SCREENSPACE_TEXTURE(_CameraMotionVectorsTexture);
            float4 _CameraMotionVectorsTexture_TexelSize;
            
            // AudioLink
            sampler2D _AudioTexture;

            // Depthの表示補正用
            float _MaxDepth;

            v2f vert (appdata v)
            {
                v2f o;
                //UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float4 col = float4(0, 0, 0, 1);
                
                i.uv.x *= 3;
                i.uv.y *= 2;
                const float floorU = floor(i.uv.x);
                // UNITY_UV_STARTS_AT_TOP のことを考える必要がある気がする
                if (floor(i.uv.y) < 1.0)
                {
                    // 下?
                    if (floorU < 2.0)
                    {
                        // Grab
                        #if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
                            // _GrabTextureが配列になるので横に並べて表示
                            float2 grabUV = frac(i.uv.xy);
                            grabUV.y = 1.0 - grabUV.y; // なぜか上下が逆
                            col = UNITY_SAMPLE_TEX2DARRAY(_GrabTexture, float3(grabUV, floor(i.uv.x)));
                        #else
                            i.uv.x /= 2.0; // 横2マス分で表示
                            col = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture, i.uv);
                        #endif
                    }
                    else
                    {
                        // AudioLink
                        float4 c = tex2D(_AudioTexture, frac(i.uv));
                        c = saturate(c) * 0.8; // まぶしすぎた
                        col = float4(c.xyz, 1);
                    }
                }
                else
                {
                    // 上?
                    if (floorU < 2.0)
                    {
                        // Depth
                        float depth = 0;
                        #if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
                            depth = UNITY_SAMPLE_TEX2DARRAY(_CameraDepthTexture, float3(frac(i.uv), floor(i.uv.x))).r;
                        #else
                            i.uv.x /= 2.0; // 横2マス分で表示
                            depth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(float4(frac(i.uv), 1, 1)));
                        #endif

                        depth = saturate(lerp(0, 1, LinearEyeDepth(depth) / _MaxDepth));
                        //depth = Linear01Depth(depth);
                        col = float4(depth, depth, depth, 1);
                    }
                    else
                    {
                        i.uv = frac(i.uv);
                        i.uv.y *= 2;
                        if (floor(i.uv.y) < 1.0)
                        {
                            // 下
                            // DepthNormals
                            float4 depthNormal;
                            #if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
                                i.uv.x *= 2.0; // 横2マス分に
                                depthNormal = UNITY_SAMPLE_TEX2DARRAY(_CameraDepthNormalsTexture, float3(frac(i.uv), floor(i.uv.x)));
                            #else
                                depthNormal = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraDepthNormalsTexture, frac(i.uv));
                            #endif
                            col = float4(depthNormal.xyz, 1);
                        }
                        else
                        {
                            // 上
                            // MotionVectors
                            float2 v;
                            #if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
                                i.uv.x *= 2.0; // 横2マス分に
                                v = UNITY_SAMPLE_TEX2DARRAY(_CameraMotionVectorsTexture, float3(frac(i.uv), floor(i.uv.x))).rg;
                            #else
                                v = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraMotionVectorsTexture, frac(i.uv)).rg;
                            #endif
                            
                            v *= _CameraMotionVectorsTexture_TexelSize.zw;
                            v += 0.5;
                            col = float4(v, 0, 1);
                        }
                    }
                }
                return saturate(col);
            }
            ENDCG
        }
    }
}
