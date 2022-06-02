#ifndef TMP3D_PROPERTIES_CG_INCLUDED
#define TMP3D_PROPERTIES_CG_INCLUDED

// General
uniform sampler2D   _FaceTex;
fixed4				_Color;
uniform float		_WeightBold;
uniform float 		_WeightNormal;

// 3D
sampler2D _DepthAlbedo;

// Outline
uniform fixed4		_OutlineColor;
uniform float		_OutlineWidth;

// Font Atlas properties
uniform sampler2D	_MainTex;
uniform float		_TextureWidth;
uniform float		_TextureHeight;
uniform float 		_GradientScale;

// TMP INTERNAL
uniform float		_ScaleRatioA;
uniform float		_ScaleRatioB;
uniform float		_ScaleRatioC;

// Used by Unity internally to handle Texture Tiling and Offset.
float4 _MainTex_TexelSize;
float4 _FaceTex_ST;
float4 _OutlineTex_ST;

#endif