#ifndef RAYMARCHING_SDFMARCHER_CG_INCLUDED
#define RAYMARCHING_SDFMARCHER_CG_INCLUDED

#include "Common.cginc"

float Temp_Progress;
tmp3d_g2f Temp_Input;

float _RaymarchMinStep;

void InitializeRaymarcher(tmp3d_g2f input)
{
	InitializeRaymarching(input);

	Temp_Progress = 0;
	Temp_Input = input;
}

void NextRaymarch(float offset)
{
	Temp_LocalPos = GetRaymarchLocalPosition(Temp_Progress);
	Temp_Mask3D = PositionToMask(Temp_LocalPos, Temp_Input);
	Temp_Bound = IsInBounds(Temp_Mask3D);
	Temp_Value = 1 - SampleSDF3D(saturate(Temp_Mask3D), Temp_Input);

	float sdfDistance = GradientToLocalLength(Temp_Input, Temp_Value, offset);
	float3 viewDir = GetRaymarchLocalDirection();
	float length1 = length(viewDir.xy);
	float ratio = sdfDistance / length1;

	Temp_Progress += max(length(viewDir) * ratio, _RaymarchMinStep);
}

#endif