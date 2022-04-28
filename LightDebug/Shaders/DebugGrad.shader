Shader "Xlwnya/Debug/Gradient"
{
    Properties
    {
        _ColorOffset ("ColorOffset", Float) = 0.15
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
            "DisableBatching" = "True"
        }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma target 3.0
            
            #pragma multi_compile_instancing
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 objectPos : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _ColorOffset;
            
            v2f vert (appdata_base v)
            {
                v2f o;
                //UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.objectPos = v.vertex;
                
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float4 col;
                if (i.objectPos.y >= _ColorOffset)
                {
                    col = unity_AmbientSky;
                } else if (i.objectPos.y > -_ColorOffset)
                {
                    col = unity_AmbientEquator;
                } else
                {
                    col = unity_AmbientGround;
                }
                return col;
            }
            ENDCG
        }
    }
}
