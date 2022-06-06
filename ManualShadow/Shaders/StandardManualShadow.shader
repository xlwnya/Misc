Shader "Xlwnya/ManualShadow/StandardManualShadow"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        
        _ManualShadowTex ("ManualShadowTex", 2D) = "white" {}
        _CameraMatrixR0 ("CameraMatrixR0", Vector) = (0, 0, 0, 0)
        _CameraMatrixR1 ("CameraMatrixR1", Vector) = (0, 0, 0, 0)
        _CameraMatrixR2 ("CameraMatrixR2", Vector) = (0, 0, 0, 0)
        _CameraMatrixR3 ("CameraMatrixR3", Vector) = (0, 0, 0, 0)
        _CameraSize ("CameraSize", Vector) = (100, 100, 1, 1)
        _NearClipPlane ("NearClipPlane", Float) = 1
        _FarClipPlane ("FarClipPlane", Float) = 200
        _MinVariance ("MinVariance", Float) = 0.0001
        _VarianceScale ("VarianceScale", Float) = 0.01
        _ShadowAtten ("ShadowAtten", Float) = 0.4
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

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
        float _ShadowAtten;

        float CalcManualShadow(float3 worldPos)
        {
            float4x4 mat = float4x4(_CameraMatrixR0, _CameraMatrixR1, _CameraMatrixR2, _CameraMatrixR3);

            float4 camPos = mul(mat, float4(worldPos, 1));
            camPos.x /= _CameraSize.x * _CameraSize.z;
            camPos.y /= _CameraSize.y * _CameraSize.w;

            float2 manualShadowDepth = tex2Dlod(_ManualShadowTex, float4(camPos.xy / 2.0 + 0.5, 0, 0));
            float lineDepth = manualShadowDepth.x;
            float lineWorldDepth = saturate((-camPos.z - _NearClipPlane) / _FarClipPlane);

            float c = lineWorldDepth > lineDepth ? 0.0 : 1.0;
            //c = lineWorldDepth;
            //c = lineDepth;

            float atten = c;
            if (lineDepth < lineWorldDepth)
            {
                // 影有り
                float depthSq = manualShadowDepth.x * manualShadowDepth.x;
                float variance = saturate(max(abs(manualShadowDepth.y - depthSq) * _VarianceScale, _MinVariance));
                float md = lineWorldDepth - lineDepth;
                float litFactor = variance / (variance + md*md);
                atten = lerp(_ShadowAtten, 1.0, litFactor);

                //atten = variance;
            }
            
            return atten;
        }

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            float atten = CalcManualShadow(IN.worldPos);
            o.Albedo = c.rgb * atten;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
