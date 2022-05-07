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
	maskUV.x = saturate(lerp(input.boundariesUV.x, input.boundariesUV.z, mask3D.x));
	maskUV.y = saturate(lerp(input.boundariesUV.y, input.boundariesUV.w, mask3D.y));
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
	float3 mask3D = float3(-1,-1,-1);
	mask3D.x = InverseLerp(input.boundariesLocal.x, input.boundariesLocal.z, localPos.x);
	mask3D.y = InverseLerp(input.boundariesLocal.y, input.boundariesLocal.w, localPos.y);
	mask3D.z = InverseLerp(input.boundariesLocalZ.x, input.boundariesLocalZ.y, localPos.z);
	return mask3D;
}

float GradientToLocalLength(tmp3d_g2f input)
{
	float l = abs(input.boundariesLocal.x - input.boundariesLocal.z);
	return l * 0.01 * _GradientScale;
}

float3 Temp_ViewDir;
float3 Temp_LocalStartPos;
float3 Temp_LocalPos;

void PrepareTMP3DRaymarch(tmp3d_g2f input)
{
	float3 viewDir = normalize(input.worldPos.xyz - _WorldSpaceCameraPos.xyz);

	// TODO: This "if" is ugly...
	if (unity_OrthoParams.w >= 0.5)
	{
		viewDir = normalize(mul((float3x3)unity_CameraToWorld, float3(0, 0, 1)));
	}

	Temp_LocalPos = mul(unity_WorldToObject, float4(input.worldPos.xyz, 1));
	Temp_LocalStartPos = Temp_LocalPos;
	Temp_ViewDir = mul((float3x3)unity_WorldToObject, viewDir);
}

float3 ProjectRayOntoPlane(float3 origin, float3 direction, float3 normal, float distance)
{
	float denom = dot(normal, direction);

	if (abs(denom) <= 1e-3)
		return 0;

	float t = -(dot(normal, origin) + distance) / dot(normal, direction);

	if (t <= 1e-3)
		return 0;

	return t * direction;
}

void PrepareTMP3DRaymarchInverted(tmp3d_g2f input)
{
	PrepareTMP3DRaymarch(input);

	float3 negViewDir = -Temp_ViewDir;
	float3 x = ProjectRayOntoPlane(Temp_LocalPos, negViewDir, float3(-1, 0, 0), input.boundariesLocal.x);
	x += ProjectRayOntoPlane(Temp_LocalPos, negViewDir, float3(-1, 0, 0), input.boundariesLocal.z);

	float3 y = ProjectRayOntoPlane(Temp_LocalPos, negViewDir, float3(0, -1, 0), input.boundariesLocal.y);
	y += ProjectRayOntoPlane(Temp_LocalPos, negViewDir, float3(0, -1, 0), input.boundariesLocal.w);

	float3 z = ProjectRayOntoPlane(Temp_LocalPos, negViewDir, float3(0, 0, -1), input.boundariesLocalZ.x);
	z += ProjectRayOntoPlane(Temp_LocalPos, negViewDir, float3(0, 0, -1), input.boundariesLocalZ.y);

	float3 c = mul((float3x3)unity_WorldToObject, _WorldSpaceCameraPos.xyz - input.worldPos.xyz);

	float xL = length(x);
	float yL = length(y);
	float zL = length(z);
	float cL = length(c);

	// TODO: This is majorly ugly...
	if (cL <= xL && cL <= yL && cL <= zL)
	{
		Temp_LocalPos += c;
		Temp_LocalStartPos = Temp_LocalPos;
		return;
	}

	if (xL <= yL && xL <= zL)
	{
		Temp_LocalPos += x;
		Temp_LocalStartPos = Temp_LocalPos;
		return;
	}

	if (yL <= zL)
	{
		Temp_LocalPos += y;
		Temp_LocalStartPos = Temp_LocalPos;
		return;
	}

	Temp_LocalPos += z;
	Temp_LocalStartPos = Temp_LocalPos;
}

float3 GetRaymarchLocalPosition()
{
	return Temp_LocalPos;
}

float3 GetRaymarchWorldPosition()
{
	return mul(unity_ObjectToWorld, float4(Temp_LocalPos.xyz, 1));
}

float3 GetRaymarchLocalDirection()
{
	return Temp_ViewDir;
}

void ProgressRaymarch(float progress)
{
	Temp_LocalPos += Temp_ViewDir * max(progress, 0.005);
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
tmp3d_g2f CreateVertex(tmp3d_v2g input, float3 positionOffset, float4 boundariesUV, float4 boundariesLocal, float2 boundariesLocalZ)
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

	return output;
}

void TMP3D_FILLGEOMETRY(triangle tmp3d_v2g input[3], inout TriangleStream<tmp3d_g2f> triStream, float3 def, float3 normal, float4 boundariesUV, float4 boundariesLocal, float2 boundariesLocalZ)
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

void TMP3D_FILLGEOMETRY_INVERTED(triangle tmp3d_v2g input[3], inout TriangleStream<tmp3d_g2f> triStream, float3 def, float3 normal, float4 boundariesUV, float4 boundariesLocal, float2 boundariesLocalZ)
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

	float minUVx = min(input[0].texcoord0.x, min(input[1].texcoord0.x, input[2].texcoord0.x));
	float minUVy = min(input[0].texcoord0.y, min(input[1].texcoord0.y, input[2].texcoord0.y));
	float maxUVx = max(input[0].texcoord0.x, max(input[1].texcoord0.x, input[2].texcoord0.x));
	float maxUVy = max(input[0].texcoord0.y, max(input[1].texcoord0.y, input[2].texcoord0.y));
	float4 boundariesUV = float4(minUVx, minUVy, maxUVx, maxUVy);

	float3 v0local = mul(unity_WorldToObject, float4(input[0].position.xyz, 1)).xyz;
	float3 v1local = mul(unity_WorldToObject, float4(input[1].position.xyz, 1)).xyz;
	float3 v2local = mul(unity_WorldToObject, float4(input[2].position.xyz, 1)).xyz;

	float minWorldx = min(v0local.x, min(v1local.x, v2local.x));
	float minWorldy = min(v0local.y, min(v1local.y, v2local.y));
	float maxWorldx = max(v0local.x, max(v1local.x, v2local.x));
	float maxWorldy = max(v0local.y, max(v1local.y, v2local.y));
	float4 boundariesLocal = float4(minWorldx, minWorldy, maxWorldx, maxWorldy);

	float minWorldz = min(v0local.z, min(v1local.z, v2local.z));
	float maxWorldz = max(v0local.z, max(v1local.z, v2local.z));
	float2 boundariesLocalZ = float2(minWorldz - depth, maxWorldz);

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

	float minUVx = min(input[0].texcoord0.x, min(input[1].texcoord0.x, input[2].texcoord0.x));
	float minUVy = min(input[0].texcoord0.y, min(input[1].texcoord0.y, input[2].texcoord0.y));
	float maxUVx = max(input[0].texcoord0.x, max(input[1].texcoord0.x, input[2].texcoord0.x));
	float maxUVy = max(input[0].texcoord0.y, max(input[1].texcoord0.y, input[2].texcoord0.y));
	float4 boundariesUV = float4(minUVx, minUVy, maxUVx, maxUVy);

	float3 v0local = mul(unity_WorldToObject, float4(input[0].position.xyz, 1)).xyz;
	float3 v1local = mul(unity_WorldToObject, float4(input[1].position.xyz, 1)).xyz;
	float3 v2local = mul(unity_WorldToObject, float4(input[2].position.xyz, 1)).xyz;

	float minWorldx = min(v0local.x, min(v1local.x, v2local.x));
	float minWorldy = min(v0local.y, min(v1local.y, v2local.y));
	float maxWorldx = max(v0local.x, max(v1local.x, v2local.x));
	float maxWorldy = max(v0local.y, max(v1local.y, v2local.y));
	float4 boundariesLocal = float4(minWorldx, minWorldy, maxWorldx, maxWorldy);

	float minWorldz = min(v0local.z, min(v1local.z, v2local.z));
	float maxWorldz = max(v0local.z, max(v1local.z, v2local.z));
	float2 boundariesLocalZ = float2(minWorldz - depth, maxWorldz);

	TMP3D_FILLGEOMETRY_INVERTED(input, triStream, def, normal, boundariesUV, boundariesLocal, boundariesLocalZ);
}

#endif