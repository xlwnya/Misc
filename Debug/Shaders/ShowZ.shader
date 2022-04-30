Shader "Xlwnya/ShowZ"
{
    Properties
    {
        _MaxDepth ("Max depth", float) = 1
    }

    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "Queue" = "Transparent+500"
        }
        LOD 200

        Pass {
            ZWrite Off
            ZTest Always

            Blend One Zero

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"

            float _MaxDepth;

            // デプスバッファ/Zバッファ
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screen_pos : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (const appdata v)
            {
                v2f o;
                //UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                // Object座標->Projection座標
                o.vertex = UnityObjectToClipPos(v.vertex);
                // Projection座標->Screen座標
                o.screen_pos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (const v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                // デプステクスチャのカメラから見た奥行き(EyeSpaceDepth)
                float depth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screen_pos));
                depth = saturate(lerp(0, 1, LinearEyeDepth(depth) / _MaxDepth));
                //float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screen_pos)));
                //float c = saturate(lerp(0, 1, depth / _MaxDepth));
                return fixed4(depth, depth, depth, 1);
            }
            ENDCG
        }
    }

    Fallback Off
}
