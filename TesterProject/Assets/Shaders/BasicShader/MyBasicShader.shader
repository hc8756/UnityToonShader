Shader "Unlit/MyBasicShader"
{
    //Properties documentation: https://docs.unity3d.com/2021.3/Documentation/Manual/SL-Properties.html
    //Information to be held in HLSL constant buffer
    Properties{
        _MyDiffuseTexture("Diffuse Texture", 2D) = "grey" {}
        _MyNormalTexture("Normal Texture", 2D) = "bump" {}
        _MySpecularTexture("Specular Texture", 2D) = "white" {}
        _MyRoughnessTexture("Roughness Texture", 2D) = "white" {}
        _MyAOTexture("AO Texture", 2D) = "white" {}
        _MyState("Enum Index", Float) = 1
    }
    SubShader
    {
        //Subshader tag documentation: https://docs.unity3d.com/2021.3/Documentation/Manual/SL-SubShaderTags.html
        Tags { "RenderPipeline"="UniversalPipeline" }

        Pass
        {
            Name "ForwardLit"
            //Pass tag documentation:
            //https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@11.0/manual/urp-shaders/urp-shaderlab-pass-tags.html#urp-pass-tags-lightmode
            Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
                //Tell compiler to use Vertex and Fragment functions at correct points of rendering pipeline
                #pragma vertex Vertex
                #pragma fragment Fragment
                //Each multi compile creates a variant of shader which URP is able to choose from
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
                #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
                #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
                #include "ForwardLit.hlsl"
            ENDHLSL
        }
        Pass{
           Name "ShadowPass"
            Tags {"LightMode" = "ShadowCaster"}
            HLSLPROGRAM
                #pragma vertex Vertex
                #pragma fragment Fragment
 
                #include "ForwardLitShadows.hlsl"
            ENDHLSL
        }
    }

    Fallback "Diffuse"
}
