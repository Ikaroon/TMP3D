#ifndef RAYMARCHING_COMMON_CG_INCLUDED
#define RAYMARCHING_COMMON_CG_INCLUDED

#pragma multi_compile _VOLUMEMODE_SURFACE _VOLUMEMODE_FULL

#include "../TMP3D_Common.cginc"

float4x4 Temp_L2W;
float4x4 Temp_W2L;

float3 Temp_ViewDir;
float3 Temp_LocalStartPos;

float3 Temp_LocalPos;
float3 GetRaymarchLocalPos()
{
	return Temp_LocalPos;
}
float3 GetRaymarchTrueLocalPos()
{
	return mul((float3x3)Temp_L2W, Temp_LocalPos.xyz);
}

float Temp_Bound;
float GetRaymarchBound()
{
	return Temp_Bound;
}

float Temp_Value;
float GetRaymarchValue()
{
	return Temp_Value;
}

float3 Temp_Mask3D;
float3 GetRaymarchMask3D()
{
	return Temp_Mask3D;
}

void PrepareTMP3DRaymarch(tmp3d_g2f input)
{
	float3 viewDir = normalize(input.worldPos.xyz - _WorldSpaceCameraPos.xyz);
	viewDir = lerp(viewDir, normalize(mul((float3x3)unity_CameraToWorld, float3(0, 0, 1))), unity_OrthoParams.w);

	viewDir = float3(0,0,1);

	Temp_LocalStartPos = mul(unity_WorldToObject, float4(input.worldPos.xyz, 1));
	Temp_L2W = quaternion_to_matrix(input.quaternion);
	Temp_W2L = inverse(Temp_L2W);
	Temp_LocalStartPos = mul(Temp_W2L, float4(Temp_LocalStartPos.xyz, 1));

	if (UNITY_MATRIX_P[3][3] == 0)
		viewDir = WorldSpaceViewDir(float4(Temp_LocalStartPos.xyz, 1)).xyz;

	Temp_ViewDir = mul((float3x3)unity_WorldToObject, viewDir);
	Temp_ViewDir = mul((float3x3)Temp_W2L, Temp_ViewDir);
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
	float3 x = ProjectRayOntoPlane(Temp_LocalStartPos, negViewDir, float3(-1, 0, 0), input.boundariesLocal.x);
	x += ProjectRayOntoPlane(Temp_LocalStartPos, negViewDir, float3(-1, 0, 0), input.boundariesLocal.z);

	float3 y = ProjectRayOntoPlane(Temp_LocalStartPos, negViewDir, float3(0, -1, 0), input.boundariesLocal.y);
	y += ProjectRayOntoPlane(Temp_LocalStartPos, negViewDir, float3(0, -1, 0), input.boundariesLocal.w);

	float3 z = ProjectRayOntoPlane(Temp_LocalStartPos, negViewDir, float3(0, 0, -1), input.boundariesLocalZ.x);
	z += ProjectRayOntoPlane(Temp_LocalStartPos, negViewDir, float3(0, 0, -1), input.boundariesLocalZ.y);

	float3 c = mul((float3x3)unity_WorldToObject, _WorldSpaceCameraPos.xyz - input.worldPos.xyz);
	c = mul((float3x3)Temp_W2L, c);

	float xL = length(x);
	float yL = length(y);
	float zL = length(z);
	float cL = length(c);

	// TODO: This is majorly ugly...
	if (cL <= xL && cL <= yL && cL <= zL)
	{
		Temp_LocalStartPos += c;
		return;
	}

	if (xL <= yL && xL <= zL)
	{
		Temp_LocalStartPos += x;
		return;
	}

	if (yL <= zL)
	{
		Temp_LocalStartPos += y;
		return;
	}

	Temp_LocalStartPos += z;
}

float3 GetRaymarchLocalPosition(float progress)
{
	return Temp_LocalStartPos + Temp_ViewDir * progress;
}

float3 GetRaymarchWorldPosition(float progress)
{
	return mul(unity_ObjectToWorld, float4(GetRaymarchWorldPosition(progress).xyz, 1));
}

float3 GetRaymarchLocalDirection()
{
	return Temp_ViewDir;
}

void InitializeRaymarching(tmp3d_g2f input)
{
	#if _VOLUMEMODE_SURFACE
	PrepareTMP3DRaymarch(input);
	#elif _VOLUMEMODE_FULL
	PrepareTMP3DRaymarchInverted(input);
	#endif
}

#endif