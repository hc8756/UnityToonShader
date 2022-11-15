Shader "Unlit/ShaderReplica"
{
	Properties{
		_MyDiffuseTexture("Diffuse Texture", 2D) = "grey" {}
		_MyNormalMap("Normal Map", 2D) = "bump" {}
		_MySpecularTexture("Specular Map", 2D) = "grey" {}
	}


	SubShader{
		Tags { "RenderPipeline" = "UniversalPipeline" }
		Pass {
			Name "ForwardLitReplica"
			Tags {"LightMode" = "UniversalForward"}
			HLSLPROGRAM
				#pragma vertex Vertex
				#pragma fragment Fragment
				#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
				//Contains useful functions
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
				CBUFFER_START(UnityPerMaterial)
				sampler2D _MyDiffuseTexture;
				sampler2D _MyNormalMap;
				sampler2D _MySpecularTexture;
				sampler2D _MyRoughnessTexture;
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
					float3 diffuseColor = tex2D(_MyDiffuseTexture, input.uv).rgb;
					
					//Extract information from normal map
					float3 unpackedNormal = tex2D(_MyNormalMap, input.uv).rgb * 2 - 1;
					
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
					float3 diffuseTerm = saturate(dot(input.normalWS, lightDir)) * lightCol;

					//Get information for specular lighting
					float specVal = tex2D(_MySpecularTexture, input.uv).r;
					float shine = 256.0f;
					float3 viewDir = normalize(_WorldSpaceCameraPos - input.positionWS);
					float3 reflectDir = reflect(-lightDir, input.normalWS);
					float RdotV = saturate(dot(reflectDir, viewDir));
					//Specular term 
					float3 specularTerm = pow(RdotV, shine) * lightCol * specVal;

					//Ambient term
					float3 ambientTerm = float3(0.4f, 0.6f, 0.75f);// sky blue color

					float shadowTerm = MainLightRealtimeShadow(TransformWorldToShadowCoord(input.positionWS));
					diffuseTerm *= (shadowTerm / 5);
					return float4 (diffuseColor*(diffuseTerm+specularTerm+ambientTerm), 1);

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

