Shader "Xlwnya/Debug/VRDetectPass"
{
    Properties
    {
        [NoScaleOffset] _MainTex ("DesktopTexture", 2D) = "white" {}
        [NoScaleOffset] _StereoTex ("VRTexture", 2D) = "white" {}
        [NoScaleOffset] _StereoSingleTex ("VRSinglePassTexture", 2D) = "white" {}
        [NoScaleOffset] _StereoSingleInstancedTex ("VRSinglePassInstancedTexture", 2D) = "white" {}
        [NoScaleOffset] _StereoMultiTex ("VRMultiViewTexture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "Lighting"="ForwardBase" "RenderType"="Opaque" }
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
            sampler2D _StereoTex;
            sampler2D _StereoSingleTex;
            sampler2D _StereoSingleInstancedTex;
            sampler2D _StereoMultiTex;

            v2f vert (appdata v)
            {
                v2f o;
                //UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                fixed4 col;
                // sample the texture
                #if defined(USING_STEREO_MATRICES)
                    col = tex2D(_StereoTex, i.uv);

                    #if defined(UNITY_SINGLE_PASS_STEREO)
                        col = tex2D(_StereoSingleTex, i.uv);
                    #endif

                    #if defined(UNITY_STEREO_INSTANCING_ENABLED)
                        col = tex2D(_StereoSingleInstancedTex, i.uv);
                    #endif

                    #if defined(UNITY_STEREO_MULTIVIEW_ENABLED)
                        col = tex2D(_StereoMultiTex, i.uv);
                    #endif
                #else
                    col = tex2D(_MainTex, i.uv);
                #endif

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
