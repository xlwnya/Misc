Shader "Xlwnya/Debug/VertexColor"
{
    Properties
    {
        _Cutoff("Cutoff", Range(0, 1)) = 0.5
        _MainTex ("Texture", 2D) = "white" {}
        [KeywordEnum(Texture, VertexColor, VertexAlpha, VertexRed, VertexBlue, VertexGreen, White)]_DEBUG_SHOW("Display", Float) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull", Float) = 2
    }
    SubShader
    {
        Tags { "RenderType"="TransparentCutout" }
        LOD 100

        Pass
        {
            Blend One Zero, One Zero
            Cull [_Cull]
            ZTest LEqual
            ZWrite On

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // make fog work
            #pragma multi_compile_fog

            #pragma target 3.0
            #pragma multi_compile_instancing

            #pragma shader_feature _DEBUG_SHOW_TEXTURE _DEBUG_SHOW_VERTEXCOLOR _DEBUG_SHOW_VERTEXALPHA _DEBUG_SHOW_WHITE _DEBUG_SHOW_VERTEXRED _DEBUG_SHOW_VERTEXBLUE _DEBUG_SHOW_VERTEXGREEN

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 pos : SV_POSITION;
                float4 color : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Cutoff = 0.5;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                UNITY_TRANSFER_FOG(o, o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                fixed4 texColor = tex2D(_MainTex, i.uv);
                clip(texColor.a - _Cutoff);

                fixed4 col = fixed4(0, 0, 0, 1);
                #if defined(_DEBUG_SHOW_VERTEXCOLOR)
                    col.rgb = i.color.rgb;
                #elif defined(_DEBUG_SHOW_VERTEXALPHA)
                    col.rgb = i.color.aaa;
                #elif defined(_DEBUG_SHOW_WHITE)
                    col.rgb = fixed3(1, 1, 1);
                #elif defined(_DEBUG_SHOW_VERTEXRED)
                    col.r = i.color.r;
                #elif defined(_DEBUG_SHOW_VERTEXBLUE)
                    col.g = i.color.g;
                #elif defined(_DEBUG_SHOW_VERTEXGREEN)
                    col.b = i.color.b;
                #else
                    col = texColor;
                #endif

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
