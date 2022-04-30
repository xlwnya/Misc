Shader "Xlwnya/OutputMotionVectorRel"
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

            #include "UnityCG.cginc"

            float3 _TargetCameraPos;
            int _TargetOnly;
            sampler2D _CameraMotionVectorsTexture;
            float4 _CameraMotionVectorsTexture_TexelSize;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            appdata vert(const appdata v)
            {
                return v;
            }

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screen_pos : TEXCOORD2;
            };

            [maxvertexcount(4)]
            void geom(point appdata IN[1], inout TriangleStream<v2f> stream) {
                const float3 worldObjectPos = mul(unity_ObjectToWorld, float4(0.0, 0.0, 0.0, 1.0)).xyz;
                // 特定のカメラ以外で処理を停止する
                if (_TargetOnly && 0.01 < distance(worldObjectPos, _WorldSpaceCameraPos)) {
                    return;
                }

                //int x = IN[0].vertex.x;
                v2f o;
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
                // MotionVectors
                float2 v = tex2Dproj(_CameraMotionVectorsTexture, UNITY_PROJ_COORD(i.screen_pos)).rg;
                v *= _CameraMotionVectorsTexture_TexelSize.zw;
                v += 0.5;
                float4 col = float4(v, 0, 1);
                return col;
            }
            ENDCG
        }
    }
}
