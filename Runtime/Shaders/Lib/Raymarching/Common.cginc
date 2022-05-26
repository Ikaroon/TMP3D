#ifndef RAYMARCHING_COMMON_CG_INCLUDED
#define RAYMARCHING_COMMON_CG_INCLUDED

#pragma multi_compile _VOLUMEMODE_SURFACE _VOLUMEMODE_FULL

#include "../TMP3D_Common.cginc"

float3 Temp_ViewDir;
float3 Temp_LocalStartPos;

float3 Temp_LocalPos;
float3 GetRaymarchLocalPos()
{
	return Temp_LocalPos;
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

	Temp_LocalStartPos = mul(unity_WorldToObject, float4(input.worldPos.xyz, 1));
	Temp_ViewDir = mul((float3x3)unity_WorldToObject, viewDir);
}

float ProjectRayOntoPlane(float3 rayOrigin, float3 rayDirection, float3 planeNormal, float3 planeOrigin)
{
	float denom = dot(planeNormal, rayDirection);

	if (abs(denom) <= 1e-3)
		return -1000;

	float t = dot(planeOrigin - rayOrigin, planeNormal) / denom;

	if (t <= 1e-3)
		return -1000;

	return t;
}

void PrepareTMP3DRaymarchInverted(tmp3d_g2f input)
{
	PrepareTMP3DRaymarch(input);

	float3 up = normalize(float3(input.boundariesLocalZ.z, input.boundariesLocal.w, 0));
	float3 side = normalize(cross(up, float3(0,0,1)));
	
	float back = input.boundariesLocalZ.x;
	float front = input.boundariesLocalZ.y;

	float bottom = input.boundariesLocal.y;
	float top = bottom + input.boundariesLocal.w;

	float left = input.boundariesLocal.x;
	float right = left + input.boundariesLocal.z;

	float3 negViewDir = normalize(-Temp_ViewDir);

	float xL = ProjectRayOntoPlane(Temp_LocalStartPos, negViewDir, side, float3(left, bottom, 0));
	float xR = ProjectRayOntoPlane(Temp_LocalStartPos, negViewDir, side, float3(right, bottom, 0));
	float x = abs(max(xL, xR));
	
	float yB = ProjectRayOntoPlane(Temp_LocalStartPos, negViewDir, float3(0, 1, 0), float3(0, bottom, 0));
	float yT = ProjectRayOntoPlane(Temp_LocalStartPos, negViewDir, float3(0, 1, 0), float3(0, top, 0));
	float y = abs(max(yB, yT));

	float zB = ProjectRayOntoPlane(Temp_LocalStartPos, negViewDir, float3(0, 0, 1), float3(0,0,back));
	float zF = ProjectRayOntoPlane(Temp_LocalStartPos, negViewDir, float3(0, 0, 1), float3(0,0,front));
	float z = abs(max(zB, zF));

	float c = length(mul((float3x3)unity_WorldToObject, _WorldSpaceCameraPos.xyz - input.worldPos.xyz));

	float dist = min(c, min(x, min(y, z)));
	Temp_LocalStartPos += negViewDir * dist;
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