Shader "Unlit/MyToonShader"
{
	Properties{
		_MyDiffuseTexture("Diffuse Texture", 2D) = "grey" {}
		_MyNormalMap("Normal Map", 2D) = "bump" {}
		_MyRampTexture("Color Ramp", 2D) = "white" {}
		_MySpecVal("Specular Value", Float)=0
	}

	SubShader{
		Tags { "RenderPipeline" = "UniversalPipeline" }
		Pass {
			Tags { "LightMode" = "UniversalForward" }
			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Fragment
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			//Contains useful functions
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
			CBUFFER_START(UnityPerMaterial)
				texture2D _MyDiffuseTexture;
				texture2D _MyNormalMap;
				texture2D _MyRampTexture;
				float _MySpecVal;
				SamplerState my_linear_clamp_sampler; //name determines sampler state settings
			CBUFFER_END

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
				
				//Extract information from diffuse map
				float3 diffuseColor = _MyDiffuseTexture.Sample(my_linear_clamp_sampler, input.uv).rgb;

				//Extract information from normal map
				float3 unpackedNormal = _MyNormalMap.Sample(my_linear_clamp_sampler, input.uv).rgb * 2 - 1;

				float3 N = normalize(input.normalWS);
				float3 B = normalize(input.bitangentWS);
				float3 T = normalize(input.tangentWS);
				float3x3 TBN = float3x3(T, B, N);

				input.normalWS = mul(unpackedNormal, TBN);

				//Get light information
				Light light = GetMainLight();
				float3 lightDir = normalize(light.direction);
				float3 lightCol = light.color;

				//Diffuse term 
				float diffuseAtten = saturate(dot(input.normalWS, lightDir));
				float3 diffuseTerm = diffuseAtten * lightCol;
				float2 rampUV = float2(diffuseAtten, 0);
				float rampMult = _MyRampTexture.Sample(my_linear_clamp_sampler, rampUV).r;//don't use input.uv, use attenuation value for u, v doesn't matter
				
				//Get information for specular lighting
				float3 viewDir = normalize(_WorldSpaceCameraPos - input.positionWS);
				float3 reflectDir = reflect(-lightDir, input.normalWS);
				float RdotV = saturate(dot(reflectDir, viewDir));
				float3 specularTerm;
				if (RdotV > _MySpecVal) {
					specularTerm = float3(_MySpecVal, _MySpecVal, _MySpecVal);
				}
				else {
					specularTerm = float3(0, 0, 0);
				}
				//Shiny= smaller, brighter highlight
				//Dull= wider, duller highlight
				
				//Ambient term
				float3 ambientTerm = float3(0.4f, 0.6f, 0.75f);// sky blue color

				float shadowTerm = MainLightRealtimeShadow(TransformWorldToShadowCoord(input.positionWS));
				diffuseTerm *= (shadowTerm / 5);	

				float3 totalColor;
				totalColor = rampMult * diffuseColor * (ambientTerm + diffuseTerm + specularTerm);
				return  float4(totalColor, 1);
			}
			ENDHLSL
		}		
		Pass{
			Name "ShadowPass"
			Tags {"LightMode" = "ShadowCaster"}
			HLSLPROGRAM
				#pragma vertex Vertex
				#pragma fragment Fragment

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

				struct VertexInput {
					float3 positionOS		: POSITION;
				};

				struct VertexOutput {
					float4 positionCS		: SV_POSITION;
				};

				VertexOutput Vertex(VertexInput input) {
					VertexOutput output;

					VertexPositionInputs posInputs = GetVertexPositionInputs(input.positionOS);
					output.positionCS = posInputs.positionCS;

					return output;
				}

				float4 Fragment(VertexOutput input) : SV_TARGET{
					return  0;
				}
			ENDHLSL
		}
	}
    Fallback "Diffuse"
}
