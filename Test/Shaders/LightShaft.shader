Shader "Xlwnya/LightShaft"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [HDR] _Color ("LightColor", Color) = (1,1,1,1)
        [HDR] _BehindColor ("_BehindColor", Color) = (1,1,1,1)
        _MaxDepth ("Max depth", float) = 1
    }

    SubShader
    {
        Tags { "Queue"="AlphaTest+50" }

        // 1st Pass (Shadow Caster)
        Pass {
            // https://forum.unity.com/threads/depth-only-shader.590620/
            // 平行投影でない場合のみDepth出力
            Tags { "LightMode" = "ShadowCaster" }
 
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"
 
            struct v2f {
                V2F_SHADOW_CASTER;
            };
 
            v2f vert( appdata_base v )
            {
                v2f o = (v2f)0;
                o.pos = float4(0,0,0,1);

                if (UNITY_MATRIX_P[3][3] != 0.0) { // 平行投影でない場合のみDepth出力
                    TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                }
                return o;
            }
 
            float4 frag( v2f i ) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }

    SubShader {
        Tags { "Queue" = "Transparent+200" }
        
        // 2nd Pass
        Pass {
            Tags {
                "LightMode" = "ForwardBase"
                "RenderType" = "Transparent"
                "IgnoreProjector" = "True"
            }
            
            //LOD 200
            Cull Back
            ZWrite Off // これ以降デプスバッファ/Zバッファを使わないはずなのでOnである必要は実際無い
            ZTest LEqual

            // ソフトに元の色に対して追加。元の色が既に明るかったら光の追加量を控えめに(後で変える)
            //Blend OneMinusDstColor One
            //Blend SrcAlpha OneMinusSrcAlpha
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.0

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float4 _BehindColor;
            float _MaxDepth;

            // デプスバッファ/Zバッファ
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screen_pos : TEXCOORD2;
            };

            v2f vert (const appdata v)
            {
                v2f o;
                // メモ:
                // Object座標: UnityのGameObject基準の座標。Batchingとかされるとメッシュベイク後の座標になるので良く分からなくなる

                // World座標: Unityのワールド座標。
                // float3 world_pos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz;
                // float3 world_dir = UnityObjectToWorldDir(v.vertex);
                // float3 world_normal = UnityObjectToWorldNormal(v.vertex);
                // なぜか方向とNormalの変換はあるっぽいのに座標を変換する物がない

                // View座標: カメラの基準のワールド座標。zが奥行きだけどマイナス方向が奥。

                // Projection座標: カメラの視界の座標。xが横yが縦でzが奥行き。
                // x/w=-1～1 y/w=-1～1 z/w=1(Near)～0(Far)?(環境によって01のどちらが遠い方か変わる)
                // w:手前を大きく遠い所を小さくするのに使う
                // o.vertex = UnityObjectToClipPos(v.vertex);

                // Screen座標: xy:実際に表示する画面をuv座標にした感じのもの(0～1?), zとwはProjection座標のまま
                // UNITY_SINGLE_PASS_STEREOの場合画面が二つ横に並んでいる
                // o.screen_pos = ComputeScreenPos(o.vertex); (これはProjection座標からの変換)


                // Object座標->Projection座標
                o.vertex = UnityObjectToClipPos(v.vertex);
                // Projection座標->Screen座標
                o.screen_pos = ComputeScreenPos(o.vertex);
                // Screen座標のzにView座標のz(カメラから見た奥行き(EyeSpaceDepth)を設定する)(恐らくfragに行ったときに良い感じに補完されてそれっぽい値になるはず)
                COMPUTE_EYEDEPTH(o.screen_pos.z);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (const v2f i) : SV_Target
            {
                const float frag_depth = i.screen_pos.z;

                // tex2Dproj: uv/wをしてからtex2Dする(
                // SAMPLE_DEPTH_TEXTURE_PROJ: (tex2Dproj(sampler, uv).r)
                // LinearEyeDepth: デプステクスチャの値をEyeSpaceDepthに変換
                // デプステクスチャのカメラから見た奥行き(EyeSpaceDepth)
                const float camera_depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screen_pos)));
                const float depth = camera_depth - frag_depth;
                if (depth < 0) return _BehindColor;
                float alpha = saturate(lerp(0, _Color.a, depth / _MaxDepth));
                return fixed4(_Color.rgb * (_Color.a + alpha) / 2, alpha);
            }
            ENDCG
        }
    }

    Fallback Off
}
