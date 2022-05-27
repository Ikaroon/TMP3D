#ifndef RAYMARCHING_TEMPORALMARCHER_CG_INCLUDED
#define RAYMARCHING_TEMPORALMARCHER_CG_INCLUDED

#include "Common.cginc"

#pragma require 2darray

float Temp_Progress;
tmp3d_g2f Temp_Input;
float Temp_ActualStepLength;

float _RaymarchStepLength;

UNITY_DECLARE_TEX2DARRAY(_RaymarchBlueNoise);
float4 _RaymarchBlueNoise_TexelSize;
float _RaymarchBlueNoise_Slices;
float _RaymarchBlueNoise_Speed;
float _RaymarchBlueNoise_Offset;

void InitializeRaymarcher(tmp3d_g2f input)
{
	InitializeRaymarching(input);

	float4 screenPos = ComputeScreenPos(input.position);
	float2 screenUV = screenPos.xy * _RaymarchBlueNoise_TexelSize.xy;

	float offset = UNITY_SAMPLE_TEX2DARRAY(_RaymarchBlueNoise, float3(screenUV, (_Time.w * _RaymarchBlueNoise_Speed) % _RaymarchBlueNoise_Slices));
	float localOffset = lerp(0, _RaymarchBlueNoise_Offset, offset);

	Temp_ActualStepLength = localOffset * _RaymarchStepLength;

	Temp_Progress = 0;
	Temp_Input = input;
}

void NextRaymarch(float offset)
{
	Temp_LocalPos = GetRaymarchLocalPosition(Temp_Progress);
	Temp_Mask3D = PositionToMask(Temp_LocalPos, Temp_Input);
	Temp_Bound = IsInBounds(Temp_Mask3D);
	Temp_Value = 1 - SampleSDF3D(saturate(Temp_Mask3D), Temp_Input);

	Temp_Progress += Temp_ActualStepLength;
}

#endif