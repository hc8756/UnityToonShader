#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"// not in core.hlsl, must be included separately

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