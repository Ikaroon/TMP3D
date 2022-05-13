#ifndef TMP3D_COMMON_CG_INCLUDED
#define TMP3D_COMMON_CG_INCLUDED

#include "TMP3D_Structs.cginc"
#include "TMP3D_Properties.cginc"

float InverseLerp(float a, float b, float x)
{
	return (x - a) * (1 / (b - a));
}

float SampleSDF3D(float3 mask3D, tmp3d_g2f input)
{
	float2 maskUV = float2(0, 0);
	maskUV.x = saturate(lerp(input.boundariesUV.x, input.boundariesUV.x + input.boundariesUV.z, mask3D.x));
	maskUV.y = saturate(lerp(input.boundariesUV.y, input.boundariesUV.y + input.boundariesUV.w, mask3D.y));
	return tex2D(_MainTex, maskUV).a;
}

// tests if a fragment is outside of bounds
float IsInBounds(float3 mask3D)
{
	float clipX = -(abs(mask3D.x - 0.5) - 0.5) + 0.01;
	float clipY = -(abs(mask3D.y - 0.5) - 0.5) + 0.01;
	float clipZ = -(abs(mask3D.z - 0.5) - 0.5) + 0.01;
	return min(0, min(clipX, min(clipY, clipZ)));
}

// Clips a fragment if outside of bounds
void ClipBounds(float3 mask3D)
{
	clip(IsInBounds(mask3D));
}

float3 PositionToMask(float3 localPos, tmp3d_g2f input)
{
	float3 mask3D = float3(-1, -1, -1);
	mask3D.y = InverseLerp(input.boundariesLocal.y, input.boundariesLocal.y + input.boundariesLocal.w, localPos.y);
	float xOffset = saturate(mask3D.y) * input.boundariesLocalZ.z;
	mask3D.x = InverseLerp(input.boundariesLocal.x, input.boundariesLocal.x + input.boundariesLocal.z, localPos.x - xOffset);
	mask3D.z = InverseLerp(input.boundariesLocalZ.x, input.boundariesLocalZ.y, localPos.z);
	return mask3D;
}

float GradientToLocalLength(tmp3d_g2f input)
{
	float l = input.boundariesLocal.z;
	return l * 0.01 * _GradientScale;
}

tmp3d_v2g TMP3D_VERT(tmp3d_a2v input)
{
	tmp3d_v2g output;

	output.position = mul(unity_ObjectToWorld, input.position);
	output.normal = mul(unity_ObjectToWorld, input.normal);
	output.color = input.color;
	output.texcoord0 = input.texcoord0;
	output.texcoord1 = input.texcoord1;
	output.texcoord2 = input.texcoord2;

	return output;
}

// "Creates a vertex" with an offset and boundary values
tmp3d_g2f CreateVertex(tmp3d_v2g input, float3 positionOffset, float4 boundariesUV, float4 boundariesLocal, float4 boundariesLocalZ)
{
	tmp3d_g2f output;

	input.normal = mul(unity_WorldToObject, input.normal);

	UNITY_INITIALIZE_OUTPUT(tmp3d_g2f, output);
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

	input.position /= input.position.w;

	output.worldPos = input.position;
	output.worldPos.xyz += positionOffset;
	float4 vert = mul(unity_WorldToObject, output.worldPos);
	float4 vPosition = UnityObjectToClipPos(vert);

	output.position = vPosition;
	output.color = input.color;
	output.atlas = input.texcoord0;
	output.boundariesUV = boundariesUV;
	output.boundariesLocal = boundariesLocal;
	output.boundariesLocalZ = boundariesLocalZ;
	output.tmp3d = input.texcoord2;
	output.tmp = input.texcoord1;

	return output;
}

void TMP3D_FILLGEOMETRY(triangle tmp3d_v2g input[3], inout TriangleStream<tmp3d_g2f> triStream, float3 def, float3 normal, float4 boundariesUV, float4 boundariesLocal, float4 boundariesLocalZ)
{
	// Top
	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[0], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[2], normal, boundariesUV, boundariesLocal, boundariesLocalZ));

	// Bottom
	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[2], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[0], def, boundariesUV, boundariesLocal, boundariesLocalZ));

	// Side A
	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[0], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[0], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], normal, boundariesUV, boundariesLocal, boundariesLocalZ));

	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[0], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], normal, boundariesUV, boundariesLocal, boundariesLocalZ));

	// Side B
	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[1], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[2], normal, boundariesUV, boundariesLocal, boundariesLocalZ));

	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[1], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[2], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[2], normal, boundariesUV, boundariesLocal, boundariesLocalZ));

	// Side C is in between of the quad's triangles and not wanted
}

void TMP3D_FILLGEOMETRY_INVERTED(triangle tmp3d_v2g input[3], inout TriangleStream<tmp3d_g2f> triStream, float3 def, float3 normal, float4 boundariesUV, float4 boundariesLocal, float4 boundariesLocalZ)
{
	// Top
	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[0], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[2], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], normal, boundariesUV, boundariesLocal, boundariesLocalZ));

	// Bottom
	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[2], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[0], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], def, boundariesUV, boundariesLocal, boundariesLocalZ));

	// Side A
	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[0], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[0], def, boundariesUV, boundariesLocal, boundariesLocalZ));

	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[0], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], def, boundariesUV, boundariesLocal, boundariesLocalZ));

	// Side B
	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[1], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[2], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], def, boundariesUV, boundariesLocal, boundariesLocalZ));

	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[1], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[2], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[2], def, boundariesUV, boundariesLocal, boundariesLocalZ));

	// Side C is in between of the quad's triangles and not wanted
}

// Extrudes the TMP quads
[maxvertexcount(24)]
void TMP3D_GEOM(triangle tmp3d_v2g input[3], inout TriangleStream<tmp3d_g2f> triStream)
{
	tmp3d_g2f o;

	float3 def = float3(0, 0, 0);
	float depth = input[0].texcoord2.r;
	float3 normal = input[0].normal * depth;

	float skewUV = abs(input[1].texcoord0.x - input[0].texcoord0.x);
	float widthUV = abs(input[2].texcoord0.x - input[1].texcoord0.x);
	float heightUV = abs(input[1].texcoord0.y - input[0].texcoord0.y);
	float xUV = min(input[0].texcoord0.x, input[2].texcoord0.x);
	float yUV = min(input[0].texcoord0.y, input[1].texcoord0.y);
	float4 boundariesUV = float4(xUV, yUV, widthUV, heightUV);

	float3 v0local = mul(unity_WorldToObject, float4(input[0].position.xyz, 1)).xyz;
	float3 v1local = mul(unity_WorldToObject, float4(input[1].position.xyz, 1)).xyz;
	float3 v2local = mul(unity_WorldToObject, float4(input[2].position.xyz, 1)).xyz;

	float skewLocal = abs(v1local.x - v0local.x);
	float widthLocal = abs(v2local.x - v1local.x);
	float heightLocal = abs(v1local.y - v0local.y);
	float xLocal = min(v0local.x, v2local.x);
	float yLocal = min(v0local.y, v1local.y);
	float4 boundariesLocal = float4(xLocal, yLocal, widthLocal, heightLocal);

	float4 boundariesLocalZ = float4(-depth, 0, skewLocal, skewUV);

	TMP3D_FILLGEOMETRY(input, triStream, def, normal, boundariesUV, boundariesLocal, boundariesLocalZ);
}

// Extrudes the TMP quads
[maxvertexcount(24)]
void TMP3D_GEOM_INVERTED(triangle tmp3d_v2g input[3], inout TriangleStream<tmp3d_g2f> triStream)
{
	tmp3d_g2f o;

	float3 def = float3(0, 0, 0);
	float depth = input[0].texcoord2.r;
	float3 normal = input[0].normal * depth;

	float skewUV = abs(input[1].texcoord0.x - input[0].texcoord0.x);
	float widthUV = abs(input[2].texcoord0.x - input[1].texcoord0.x);
	float heightUV = abs(input[1].texcoord0.y - input[0].texcoord0.y);
	float xUV = min(input[0].texcoord0.x, input[2].texcoord0.x);
	float yUV = min(input[0].texcoord0.y, input[1].texcoord0.y);
	float4 boundariesUV = float4(xUV, yUV, widthUV, heightUV);

	float3 v0local = mul(unity_WorldToObject, float4(input[0].position.xyz, 1)).xyz;
	float3 v1local = mul(unity_WorldToObject, float4(input[1].position.xyz, 1)).xyz;
	float3 v2local = mul(unity_WorldToObject, float4(input[2].position.xyz, 1)).xyz;

	float skewLocal = abs(v1local.x - v0local.x);
	float widthLocal = abs(v2local.x - v1local.x);
	float heightLocal = abs(v1local.y - v0local.y);
	float xLocal = min(v0local.x, v2local.x);
	float yLocal = min(v0local.y, v1local.y);
	float4 boundariesLocal = float4(xLocal, yLocal, widthLocal, heightLocal);

	float4 boundariesLocalZ = float4(-depth, 0, skewLocal, skewUV);

	TMP3D_FILLGEOMETRY_INVERTED(input, triStream, def, normal, boundariesUV, boundariesLocal, boundariesLocalZ);
}

#endif