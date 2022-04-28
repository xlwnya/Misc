Shader "Xlwnya/Debug/VertexLit"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
                float3 ambient : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (appdata_base v)
            {
                //#if !UNITY_SHOULD_SAMPLE_SH || !defined(VERTEXLIGHT_ON)
                //    return (v2f)0;
                //#endif
                
                v2f o;
                //UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);

                float3 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);

                o.ambient = 0;
                // Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
                #if UNITY_SHOULD_SAMPLE_SH
                    //#ifdef VERTEXLIGHT_ON
                        // Approximated illumination from non-important point lights
                        o.ambient = Shade4PointLights (
                            unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                            unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                            unity_4LightAtten0, worldPos, worldNormal);
                    //#endif
                #endif
                
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                float4 col = float4(i.ambient, 1.0);
                return col;
            }
            ENDCG
        }
    }
}
