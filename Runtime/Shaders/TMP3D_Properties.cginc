#ifndef TMP3D_PROPERTIES_CG_INCLUDED
#define TMP3D_PROPERTIES_CG_INCLUDED

// Face
fixed4 _FaceColor;

// 3D
sampler2D _DepthAlbedo;
float _RaymarchMinStep;

// Outline
uniform fixed4		_OutlineColor;
uniform float		_OutlineWidth;

// Font Atlas properties
uniform sampler2D	_MainTex;
uniform float		_TextureWidth;
uniform float		_TextureHeight;
uniform float 		_GradientScale;

// Used by Unity internally to handle Texture Tiling and Offset.
float4 _MainTex_TexelSize;
float4 _FaceTex_ST;
float4 _OutlineTex_ST;

#endif