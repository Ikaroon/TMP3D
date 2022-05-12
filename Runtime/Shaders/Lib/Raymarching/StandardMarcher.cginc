#ifndef RAYMARCHING_STANDARDMARCHER_CG_INCLUDED
#define RAYMARCHING_STANDARDMARCHER_CG_INCLUDED

#include "Common.cginc"

float temp_Progress;
tmp3d_g2f temp_Input;

void InitializeRaymarcher(tmp3d_g2f input)
{
	InitializeRaymarching(input);

	temp_Progress = 0;
	temp_Input = input;
}

void NextRaymarch(out float3 localPos, out float bound, out float value, float offset)
{
	localPos = GetRaymarchLocalPosition(temp_Progress);
	float3 mask3D = PositionToMask(localPos, temp_Input);
	bound = IsInBounds(mask3D);
	value = 1 - SampleSDF3D(saturate(mask3D), temp_Input);

	float sdfDistance = max((value - offset) * GradientToLocalLength(temp_Input), _RaymarchMinStep);
	float3 viewDir = GetRaymarchLocalDirection();
	float length1 = length(normalize(viewDir.xy) * sdfDistance);
	float length2 = length(viewDir.xy);

	float ratio = length1 / length2;
	viewDir *= ratio;

	temp_Progress += length(viewDir);
}

#endif