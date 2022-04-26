Shader "Xlwnya/Debug/FaceOrientation"
{
    Properties
    {
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf  Standard fullforwardshadows vertex:vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        float _Glossiness;
        float _Metallic;
        
        struct Input
        {
            float3 objectNormal;
        };
        
        void vert (inout appdata_full v, out Input o) {
            UNITY_INITIALIZE_OUTPUT(Input,o);
            o.objectNormal = v.normal;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float3 on = abs(IN.objectNormal);
            if (on.r < on.g) { on.r = -1; } else { on.g = -1; }
            if (on.r < on.b) { on.r = -1; } else { on.b = -1; }
            if (on.g < on.b) { on.g = -1; } else { on.b = -1; }
            on = step(0, on);
            on += 0.5 * (1 - step(0, dot(IN.objectNormal, on)));
            o.Albedo = on;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = 1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
