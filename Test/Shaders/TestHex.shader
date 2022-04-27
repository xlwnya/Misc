// 平面を六角形に分割してみた
Shader "Xlwnya/TestHex"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            
            static float r3 = 1.73205080756;  // sqrt(3)
            static float r3i = 0.57735026919; // 1/sqrt(3)

            // 直交<->斜交の座標変換行列 https://note.com/kakilemon/n/ne7e691c7d93c
            static float2x2 tri2cart = float2x2(1, 0.5, 0, r3/2);
            static float2x2 cart2tri = float2x2(1, -r3i, 0, 2*r3i);

            float4 hexOffset(float2 uv, float scale) {
                //return frac(uv*scale);
                const float2 triUv = mul(cart2tri, uv*scale);
                float2 offset = floor(triUv);
                float2 pos = frac(triUv);
                //return pos;
                /*
                if (pos.y > max(-2*pos.x + 1, -0.5*pos.x + 0.5)) {
                  // 右 そのまま
                } else {
                  if (pos.y > pos.x) {
                    // 左
                      pos.x += 1;
                      offset.x -= 1;
                    } else {
                      // 下
                      pos.y += 1;
                      offset.y -= 1;
                    }
                  }
                */
                float otherHex = step(pos.y, max(-2*pos.x + 1, -0.5*pos.x + 0.5)); // max(-2*pos.x + 1, -0.5*pos.x + 0.5) >= pos.y => 1
                float currentRow = step(pos.x, pos.y); // pos.y >= pos.x => 1

                //return float2(otherHex, currentRow);
                
                float uOffset = otherHex * currentRow;
                float vOffset = otherHex * (1 - currentRow);

                pos += float2(uOffset, vOffset);
                offset -= float2(uOffset, vOffset);
                pos -= float2(2.0/3, 2.0/3); // hex中心からの位置に修正

                return float4(mul(tri2cart, pos), offset);
            }

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
                //UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                //UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_SETUP_INSTANCE_ID(v);
                //UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                //UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);

                // 縦スクロール
                i.uv.y += _Time.x * 2;
                
                float2 hexUv = hexOffset(i.uv, 4);

                // 極座標化(rad -> 0-1)
                float angle = atan2(hexUv.y, hexUv.x) / UNITY_TWO_PI;
                float r = length(hexUv.xy);

                // 回転
                angle -= _Time.x *3;
                // 極座標分割(7), 0-1 -> rad
                const float theta = (frac(angle * 7 + 0.5) - 0.5) / 7 * UNITY_TWO_PI;

                // 極座標円
                const float circleSize = 0.17;
                const float circlePos = 0.3;
                float c = step(r*r + pow(circlePos, 2) - 2*r*circlePos*cos(theta), pow(circleSize, 2));
                
                float4 col = float4(c, c, c, 1);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
