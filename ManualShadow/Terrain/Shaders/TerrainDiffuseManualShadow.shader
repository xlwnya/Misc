// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Xlwnya/ManualShadow/TerrainDiffuseManualShadow" {
    Properties {
        // used in fallback on old cards & base map
        [HideInInspector] _MainTex ("BaseMap (RGB)", 2D) = "white" {}
        [HideInInspector] _Color ("Main Color", Color) = (1,1,1,1)

        [HideInInspector] _TerrainHolesTexture("Holes Map (RGB)", 2D) = "white" {}

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
 
    SubShader {
        Tags {
            "Queue" = "Geometry-100"
            "RenderType" = "Opaque"
        }

        CGPROGRAM
        #pragma surface surf Lambert vertex:SplatmapVert finalcolor:SplatmapFinalColor finalprepass:SplatmapFinalPrepass finalgbuffer:SplatmapFinalGBuffer addshadow fullforwardshadows
        #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap forwardadd
        #pragma multi_compile_fog
        #pragma multi_compile_local __ _ALPHATEST_ON
        #pragma multi_compile_local __ _NORMALMAP
        #pragma target 3.0

        #include "cginc/CustomTerrainSplatmapCommon.cginc"

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

        void surf(Input IN, inout SurfaceOutput o)
        {
            half4 splat_control;
            half weight;
            fixed4 mixedDiffuse;
            SplatmapMix(IN, splat_control, weight, mixedDiffuse, o.Normal);

            float4x4 mat = float4x4(_CameraMatrixR0, _CameraMatrixR1, _CameraMatrixR2, _CameraMatrixR3);
            
            float4 camPos = mul(mat, float4(IN.worldPos, 1));
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

            o.Albedo = mixedDiffuse.rgb * atten;
            o.Alpha = weight;
        }
        ENDCG

        UsePass "Hidden/Nature/Terrain/Utilities/PICKING"
        UsePass "Hidden/Nature/Terrain/Utilities/SELECTION"
    }

    Dependency "AddPassShader"    = "Hidden/TerrainEngine/Splatmap/Diffuse-AddPass"
    Dependency "BaseMapShader"    = "Hidden/TerrainEngine/Splatmap/Diffuse-Base"
    Dependency "BaseMapGenShader" = "Hidden/TerrainEngine/Splatmap/Diffuse-BaseGen"
    
    Fallback "Nature/Terrain/Diffuse"
}
