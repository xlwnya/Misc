Shader "Xlwnya/OutputDepthRel"
{
    Properties
    {
        [Toggle] _TargetOnly("Target Camera only", Int) = 1
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

            #include "UnityCG.cginc"

            float3 _TargetCameraPos;
            int _TargetOnly;
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

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

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                //return fixed4(i.uv.x, i.uv.y, 0, 1); // uv

                //return fixed4(0.5, 0.5, 0.5, 1); // 灰色

                //return tex2Dproj(_CameraDepthNormalsTexture, UNITY_PROJ_COORD(i.screen_pos)); // DepthNormals

                // Depth
                float depth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screen_pos));
                return float4(depth, depth, depth, 1);
            }
            ENDCG
        }
    }
}
