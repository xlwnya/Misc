Shader "Xlwnya/ManualShadow/ManualShadowDebug"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        
        _ManualShadowTex ("ManualShadowTex", 2D) = "black" {}
        _CameraMatrixR0 ("CameraMatrixR0", Vector) = (0, 0, 0, 0)
        _CameraMatrixR1 ("CameraMatrixR1", Vector) = (0, 0, 0, 0)
        _CameraMatrixR2 ("CameraMatrixR2", Vector) = (0, 0, 0, 0)
        _CameraMatrixR3 ("CameraMatrixR3", Vector) = (0, 0, 0, 0)
        _CameraSize ("CameraSize", Vector) = (100, 100, 1, 1)
        _NearClipPlane ("NearClipPlane", Float) = 1
        _FarClipPlane ("FarClipPlane", Float) = 200
        _MinVariance ("MinVariance", Float) = 0.0001
        _MipLevel ("MipLevel", Float) = 0
        _VarianceScale ("VarianceScale", Float) = 0.1
        _ShadowAtten ("ShadowAtten", Float) = 0.4
        [Toggle] _Smoothstep ("Smoothstep", int) = 0
        [KeywordEnum(Soft, Soft2, Hard)]_SHADOW_MODE("Mode", Float) = 0
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            
            #pragma shader_feature_local _SHADOW_MODE_SOFT _SHADOW_MODE_SOFT2 _SHADOW_MODE_HARD

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
                float4 worldPos : TEXCOORD1;
                UNITY_FOG_COORDS(2)
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _ManualShadowTex;

            float4 _CameraMatrixR0;
            float4 _CameraMatrixR1;
            float4 _CameraMatrixR2;
            float4 _CameraMatrixR3;
            float4 _CameraSize;
            float _NearClipPlane;
            float _FarClipPlane;
            float _MinVariance;
            float _VarianceScale;
            float _MipLevel;
            int _Smoothstep;
            float _ShadowAtten;
            float4 _BaseColor;

            v2f vert (appdata v)
            {
                v2f o;
                //UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                UNITY_TRANSFER_FOG(o,o.vertex);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_FOG(o, o.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                float4x4 mat = float4x4(_CameraMatrixR0, _CameraMatrixR1, _CameraMatrixR2, _CameraMatrixR3);
                
                float4 camPos = mul(mat, i.worldPos);
                camPos.x /= _CameraSize.x * _CameraSize.z;
                camPos.y /= _CameraSize.y * _CameraSize.w;

                float2 fakeShadowDepth = tex2Dlod(_ManualShadowTex, float4(camPos.xy / 2.0 + 0.5, 0, _MipLevel));
                float lineDepth = fakeShadowDepth.x;
                float lineWorldDepth = saturate((-camPos.z - _NearClipPlane) / _FarClipPlane);

                float c = lineWorldDepth > lineDepth ? 0.0 : 1.0;
                //c = lineCamDepth;
                //c = lineDepth;

                float atten = c;
                #ifndef _SHADOW_MODE_HARD
                if (lineDepth < lineWorldDepth)
                {
                    // 影有り
                    float depth_sq = fakeShadowDepth.x * fakeShadowDepth.x;
                    float variance = saturate(max(abs(fakeShadowDepth.y - depth_sq) * _VarianceScale, _MinVariance));
                    float md = lineWorldDepth - lineDepth;
                    #ifdef _SHADOW_MODE_SOFT
                    float lit_factor = variance / (variance + md*md);
                    #else
                    float lit_factor = variance / (variance + md*2);
                    #endif
                    if (_Smoothstep) lit_factor = smoothstep(0.0, 1.0, lit_factor); // 何となくsmoothstepする場合
                    
                    atten = lerp(_ShadowAtten, 1.0, lit_factor);
                    //atten = variance;
                }
                #endif
                
                c = atten;
                //atten = lineWorldDepth;
                //atten = lineDepth;
                //return float4(c, c, c, 1);
                
                float4 col = tex2D(_MainTex, i.uv) * _BaseColor * atten;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
