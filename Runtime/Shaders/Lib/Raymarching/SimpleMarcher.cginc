#ifndef RAYMARCHING_SIMPLEMARCHER_CG_INCLUDED
#define RAYMARCHING_SIMPLEMARCHER_CG_INCLUDED

#include "Common.cginc"

float temp_Progress;
tmp3d_g2f temp_Input;

float _RaymarchStepLength;

void InitializeRaymarcher(tmp3d_g2f input)
{
	InitializeRaymarching(input);

	temp_Progress = 0;
	temp_Input = input;
}

void NextRaymarch(float offset)
{
	Temp_LocalPos = GetRaymarchLocalPosition(temp_Progress);
	Temp_Mask3D = PositionToMask(Temp_LocalPos, temp_Input);
	Temp_Bound = IsInBounds(Temp_Mask3D);
	Temp_Value = 1 - SampleSDF3D(saturate(Temp_Mask3D), temp_Input);

	temp_Progress += _RaymarchStepLength;
}

#endif