Shader "Xlwnya/OutputDepthRelGeom"
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
            #pragma geometry geom
            #pragma fragment frag

            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            float3 _TargetCameraPos;
            int _TargetOnly;
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2g
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2g vert(const appdata v)
            {
                v2g o;
                //UNITY_INITIALIZE_OUTPUT(v2g, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = v.vertex;
                
                return o;
            }

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screen_pos : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            [maxvertexcount(4)]
            void geom(point v2g IN[1], inout TriangleStream<v2f> stream) {
                UNITY_SETUP_INSTANCE_ID(IN[0]);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN[0]);
                
                const float3 worldObjectPos = mul(unity_ObjectToWorld, float4(0.0, 0.0, 0.0, 1.0)).xyz;
                // 特定のカメラ以外で処理を停止する
                if (_TargetOnly && 0.01 < distance(worldObjectPos, _WorldSpaceCameraPos)) {
                    return;
                }

                //int x = IN[0].vertex.x;
                v2f o;
                //UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(IN[0], o);
                UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(IN[0], o);

                // 左下 左上 右下 右上
                float2 uvs[4] = { float2(-1,-1), float2(-1,1), float2(1,-1), float2(1,1) };

                UNITY_UNROLL
                for(int i = 0; i < 4; i++) {
                    // near plane の位置に板を置く
                    // ビューでNearClipに座標を置いてプロジェクションに変換(ビューではカメラの向いてる方向が-z)
                    o.vertex = mul(UNITY_MATRIX_P, float4(uvs[i], - _ProjectionParams.y, 1));
                    // 画面全体になるようにxy座標を指定(-1～1 * w)
                    o.vertex.xy = uvs[i].xy * o.vertex.w;
                    // 環境によりy座標が逆になっているので*_ProjectionParams.xして逆にする
                    o.vertex.y *= _ProjectionParams.x;
                    // 一応uvっぽい座標にする
                    o.uv = (uvs[i] + 1) / 2;
                    // ScreenPos。UNITY_SINGLE_PASS_STEREOの場合左右に画面が並ぶ形になる
                    o.screen_pos = ComputeScreenPos(o.vertex);
                    stream.Append(o);
                }
                stream.RestartStrip();
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
