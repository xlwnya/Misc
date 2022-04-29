Shader "Xlwnya/ShowLight0"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)
        [NoScaleOffset] _NumTex ("NumTex", 2D) = "white" {}
        _NumColor ("NumColor", Color) = (0, 0, 0, 1)
        _Pos_ST ("PosST", Vector) = (1, 1, 0, 0)
        _LightCol_ST ("LightColST", Vector) = (1, 1, 0, 0)
        _Digits ("Digits", Int) = 7
        _NSmall ("NSmall", Int) = 2
        _Unit ("Unit", Int) = 9
        _Value ("Value", Float) = 0.0
    }
    
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue" = "Transparent"
        }
        LOD 100

        Blend SrcAlpha OneMinusSrcAlpha
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma target 3.0
            
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;

            sampler2D _NumTex;
            float4 _NumColor;

            float4 _Pos_ST;
            float4 _LightCol_ST;
            
            float _Value;
            float _Digits;
            float _NSmall;
            float _Unit;
            
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 pos_uv : TEXCOORD1;
                float2 color_uv : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                //UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.pos_uv = TRANSFORM_TEX(v.texcoord, _Pos);
                o.color_uv = TRANSFORM_TEX(v.texcoord, _LightCol);
                
                return o;
            }

            // 複数テクスチャを半透明みたいに重ねる
            // Blend SrcAlpha OneMinusSrcAlpha
            inline float4 blend_col(const float4 src, const float4 dst)
            {
                return float4(src.xyz*src.a + dst.xyz*(1-src.a), max(src.a, dst.a));
            }

            // 数値用テクスチャは横10桁(0-9)縦2行。二行目に記号など。左から-+.単位。+は未使用。
            inline float4 frag_number(
                const float2 uv, // 数値表示部分のUV(0-1)
                const float2 raw_uv, // 生UV(tex2Dgrad用。frac等をした非連続UVだとmipmap選択が変になって変な表示になるため)
                const float value, // 表示する数値
                const float digits, // 全体の表示桁数(小数点以下&単位を含む)
                float nsmall, // 小数点以下桁数
                float unit) // 単位(数字テクスチャの桁位置で指定)
            {
                // 10進数
                const float radix = 10; // 下でlog10を使っているので変更不可
                // 単位あり
                const float has_unit = unit ? 1 : 0;

                // 整数の桁数
                const float nbig = digits - nsmall - has_unit;

                // 左からN桁目(0-)
                const float rnth = floor(uv.x * digits);
                // 桁ごとのU座標(0-1)
                // 数値テクスチャの横幅を桁ごとに10mm左右余白1mmで作成した縮小したのでUVの値を補正している(+0.1 & *10/12)
                const float nth_u = (frac(uv.x * digits) + 0.1) * 10.0 / 12.0;

                // N桁目(1は0桁目) 小数点以下はマイナス
                const float nth = nbig - rnth - 1;

                float abs_value = abs(value);

                // 単位の3桁毎切替処理(5桁目で上の単位に切り替えるので-1している)
                
                const float unit_log = floor((log10(abs_value)-1) / 3);
                if (has_unit && 0 < unit_log)
                {
                    unit -= unit_log; // 単位がテクスチャ上に右から順にm,km,Mmみたいに並んでる前提
                    abs_value /= pow(radix, unit_log*3);
                }

                // 良い感じのところでroundする
                // floatの精度が10進数7桁くらいみたいなのでなんとなくそこらへんでroundしたい
                // nsmall+1だと2999(nsmall=0)が2998になってだめだった)
                const float round_offset = min(6 - floor(log10(abs_value)), nsmall+2);
                if (round_offset > 0) abs_value = round(abs_value * pow(radix, round_offset)) / pow(radix, round_offset);

                // 表示する桁を0桁目に持ってくる
                const float nthshift = abs_value / pow(radix, nth);
                // 表示する桁の数字。+0.00001はなぜか-1されて表示される場合のための補正
                const float nthnum = floor(fmod(nthshift+0.00001, radix));
                
                float2 num_uv = float2(0, 0); // 数字用UV
                float2 dot_uv = float2(0, 0); // 記号用UV
                // 単位(指定されている場合最終桁に表示)
                if (unit && rnth+1 == digits)
                {
                    dot_uv = float2((unit + nth_u) / radix, uv.y / 2);
                }
                else
                {
                    // 数字(0以外 or 上の桁が存在 or 小数点以下)
                    if (nthnum > 0 || nthshift >= radix || nth <= 0)
                    {
                        num_uv = float2((nthnum + nth_u) / radix, (uv.y + 1) / 2); // 1行目が上にあるっぽい(UNITY_UV_STARTS_AT_TOP?)
                    }
                    // 小数点(2列目の3桁目に小数点のテクスチャを用意している)
                    if (nth == 0 && nsmall > 0) dot_uv = float2((nth_u + 2) / radix, uv.y / 2);
                    
                    // マイナス
                    if (value < 0 && nth > 0 && (nthnum < 0.1 || rnth == 0) && frac(nthshift) * radix >= 1.0)
                    {
                        dot_uv = float2(nth_u / radix, uv.y / 2);
                    }
                }

                const float4 num_col = tex2Dgrad(_NumTex, num_uv, ddx(raw_uv.x / digits), ddy(raw_uv.y / 2)) * _NumColor;
                const float4 dot_col = tex2Dgrad(_NumTex, dot_uv, ddx(raw_uv.x / digits), ddy(raw_uv.y / 2)) * _NumColor;
                
                return blend_col(dot_col, num_col);
            }

            float4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float4 col = tex2D(_MainTex, i.uv) * _Color;
                const float2 pos_uv = saturate(i.pos_uv);
                bool isLightCol = (0 <= i.color_uv.x && i.color_uv.x <= 1 && 0 <= i.color_uv.y && i.color_uv.y <= 1);

                float4 pos = _WorldSpaceLightPos0;
                float4 light_color = _LightColor0;
                float max_color = max(light_color.x, max(light_color.y, light_color.z));
                if (max_color >= 1.0) light_color /= max_color;
                
                float4 num_col = float4(0, 0, 0, 0);

                int posIndex = 3 - int(pos_uv.y * 4);

                float unit = _Unit;
                float nsmall = _NSmall;
                float posValue = 0;
                if (posIndex < 3)
                {
                    posValue = pos[posIndex];
                    if (length(pos) == 1) unit = 0;
                }
                else
                {
                    posValue = max_color;
                    unit = 0;
                    nsmall = 3;
                }

                if (_Value) posValue = _Value;
                num_col = frag_number(
                    float2(frac(pos_uv.x), frac(pos_uv.y * 4)),
                    float2(i.pos_uv.x, i.pos_uv.y * 4),
                    posValue, _Digits, nsmall, unit);
                // saturateした時にx座標の端部分の表示が怪しいので範囲外の場合透明にする
                if (pos_uv.x != i.pos_uv.x) num_col = float4(0, 0, 0, 0);

                if (i.color_uv.x > 0.5) light_color.a = 1;
                light_color = isLightCol ? light_color : float4(0, 0, 0, 0);

                col = blend_col(num_col, col);
                return blend_col(light_color, col);
            }
            ENDCG
        }
    }
}
