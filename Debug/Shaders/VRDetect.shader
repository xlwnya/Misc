﻿Shader "Xlwnya/Debug/VRDetect"
{
    Properties
    {
        _MainTex ("DesktopTexture", 2D) = "white" {}
        _StereoTex ("VRTexture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing
            
            // make fog work
            #pragma multi_compile_fog

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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _StereoTex;
            float4 _StereoTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                //UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);

                #if defined(UNITY_SINGLE_PASS_STEREO)
                    o.uv = TRANSFORM_TEX(v.uv, _StereoTex); // VR
                #else
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex); // Non VR
                #endif

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                // sample the texture
                #if defined(UNITY_SINGLE_PASS_STEREO)
                    fixed4 col = tex2D(_StereoTex, i.uv);
                #else
                    fixed4 col = tex2D(_MainTex, i.uv);
                #endif

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
