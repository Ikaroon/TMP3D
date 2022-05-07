#ifndef TMP3D_STRUCTS_CG_INCLUDED
#define TMP3D_STRUCTS_CG_INCLUDED

struct tmp3d_a2v {
	UNITY_VERTEX_INPUT_INSTANCE_ID
	float4	position		: POSITION;
	float3	normal			: NORMAL;
	fixed4	color			: COLOR;
	float2	texcoord0		: TEXCOORD0;
	float2	texcoord1		: TEXCOORD1;
	float4	texcoord2		: TEXCOORD2;
};

struct tmp3d_v2g {
	UNITY_VERTEX_INPUT_INSTANCE_ID
	float4	position		: POSITION;
	float3	normal			: NORMAL;
	fixed4	color			: COLOR;
	float2	texcoord0		: TEXCOORD0;
	float2	texcoord1		: TEXCOORD1;
	float4	texcoord2		: TEXCOORD2;
};

struct tmp3d_g2f {
	UNITY_VERTEX_INPUT_INSTANCE_ID
	float4	position			: SV_POSITION;
	fixed4	color				: COLOR;
	float2	atlas				: TEXCOORD0;
	float4	worldPos			: TEXCOORD1;
	float4	boundariesUV		: TEXCOORD2;
	float4	boundariesLocal		: TEXCOORD3;
	float2	boundariesLocalZ	: TEXCOORD4;
	float4	tmp3d				: TEXCOORD5;
};

#endif