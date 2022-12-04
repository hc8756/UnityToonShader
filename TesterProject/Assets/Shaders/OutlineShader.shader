Shader "Unlit/OutlineShader"
{
    Properties
    {
        _Thickness("Outline Thickness", Float) = 1
        _Color("Outline Color", Vector) = (0,0,0,1)
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            struct VertexInput {
                float3 positionOS		: POSITION0;
                float2 uv				: TEXCOORD;
                float3 normalOS			: NORMAL;
                float4 tangentOS		: TANGENT;
            };

            struct VertexOutput {
                float4 positionCS		: SV_POSITION;
                float3 positionWS		: POSITION1;
                float2 uv				: TEXCOORD;
                float3 normalWS			: NORMAL;
                float3 tangentWS		: TANGENT0;
                float3 bitangentWS		: TANGENT1;
            };

            CBUFFER_START(UnityPerMaterial)
                texture2D _CameraColorTexture;
                SamplerState sampler_CameraColorTexture;
                float4 _CameraColorTexture_TexelSize;
                texture2D _CameraDepthTexture;
                SamplerState sampler_CameraDepthTexture;
                float _Thickness;
                vector _Color;
            CBUFFER_END

            float4 Outline_float(float2 UV, float OutlineThickness, float4 OutlineColor)
            {
                float halfScaleFloor = floor(OutlineThickness * 0.5);
                float halfScaleCeil = ceil(OutlineThickness * 0.5);
                float2 Texel = (1.0) / float2(_CameraColorTexture_TexelSize.z, _CameraColorTexture_TexelSize.w);

                float2 uvSamples[4];
                float depthSamples[4];
                float3 colorSamples[4];

                uvSamples[0] = UV - float2(Texel.x, Texel.y) * halfScaleFloor;
                uvSamples[1] = UV + float2(Texel.x, Texel.y) * halfScaleCeil;
                uvSamples[2] = UV + float2(Texel.x * halfScaleCeil, -Texel.y * halfScaleFloor);
                uvSamples[3] = UV + float2(-Texel.x * halfScaleFloor, Texel.y * halfScaleCeil);

                for (int i = 0; i < 4; i++)
                {
                    depthSamples[i] = _CameraDepthTexture.Sample(sampler_CameraDepthTexture, uvSamples[i]).r;
                    colorSamples[i] = _CameraColorTexture.Sample(sampler_CameraColorTexture, uvSamples[i]).rgb;
                }

                // Depth
                float depthFiniteDifference0 = depthSamples[1] - depthSamples[0];
                float depthFiniteDifference1 = depthSamples[3] - depthSamples[2];
                float edgeDepth = sqrt(pow(depthFiniteDifference0, 2) + pow(depthFiniteDifference1, 2)) * 100;
                //2 is depth sensitivity
                float depthThreshold = (1 / 2) * depthSamples[0];
                edgeDepth = edgeDepth > depthThreshold ? 1 : 0;

                // Color
                float3 colorFiniteDifference0 = colorSamples[1] - colorSamples[0];
                float3 colorFiniteDifference1 = colorSamples[3] - colorSamples[2];
                float edgeColor = sqrt(dot(colorFiniteDifference0, colorFiniteDifference0) + dot(colorFiniteDifference1, colorFiniteDifference1));
                //2 is color sensitivity
                edgeColor = edgeColor > (1 / 2) ? 1 : 0;

                float edge = max(edgeDepth, edgeColor);
                float4 original = _CameraColorTexture.Sample(sampler_CameraColorTexture, uvSamples[0]).rgba;

                return ((1 - edge) * original) + (edge * lerp(original, OutlineColor, OutlineColor.a));
            }

			VertexOutput Vertex(VertexInput input) {
				VertexOutput output;
				VertexPositionInputs posInputs = GetVertexPositionInputs(input.positionOS);
				output.positionCS = posInputs.positionCS;
				output.positionWS = posInputs.positionWS;
				output.uv = input.uv;
				VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
				output.normalWS = normInputs.normalWS;
				output.tangentWS = normInputs.tangentWS;
				output.bitangentWS = normInputs.bitangentWS;
				return output;
			}

            float4 Fragment(VertexOutput input) : SV_TARGET{
                return Outline_float(input.uv,_Thickness,_Color);
			}
            ENDHLSL
        }
    }
}
