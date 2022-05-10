Shader "TextMeshPro/3D/Unlit"
{
	Properties
	{
		_FaceTex("Face Texture", 2D) = "white" {}
		_FaceUVSpeedX("Face UV Speed X", Range(-5, 5)) = 0.0
		_FaceUVSpeedY("Face UV Speed Y", Range(-5, 5)) = 0.0
		[HDR]_FaceColor("Face Color", Color) = (1,1,1,1)
		_FaceDilate("Face Dilate", Range(-1,1)) = 0

		_WeightNormal("Weight Normal", float) = 0
		_WeightBold("Weight Bold", float) = 0.5

		_ShaderFlags("Flags", float) = 0
		_ScaleRatioA("Scale RatioA", float) = 1
		_ScaleRatioB("Scale RatioB", float) = 1
		_ScaleRatioC("Scale RatioC", float) = 1

		_MainTex("Font Atlas", 2D) = "white" {}
		_TextureWidth("Texture Width", float) = 512
		_TextureHeight("Texture Height", float) = 512
		_GradientScale("Gradient Scale", float) = 5.0
		_ScaleX("Scale X", float) = 1.0
		_ScaleY("Scale Y", float) = 1.0
		_PerspectiveFilter("Perspective Correction", Range(0, 1)) = 0.875
		_Sharpness("Sharpness", Range(-1,1)) = 0

		_VertexOffsetX("Vertex OffsetX", float) = 0
		_VertexOffsetY("Vertex OffsetY", float) = 0

		_MaskCoord("Mask Coordinates", vector) = (0, 0, 32767, 32767)
		_ClipRect("Clip Rect", vector) = (-32767, -32767, 32767, 32767)
		_MaskSoftnessX("Mask SoftnessX", float) = 0
		_MaskSoftnessY("Mask SoftnessY", float) = 0

		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255

		_ColorMask("Color Mask", Float) = 15
		_Gradient("Gradient", 2D) = "white" {}

		_RaymarchMinStep("Raymarch min step", Range(0.001, 0.01)) = 0.001

		_OutlineColor("Outline Color", Color) = (0,0,0,1)
		_OutlineWidth("Outline Thickness", Range(0,1)) = 0
		_OutlineSoftness("Outline Softness", Range(0,1)) = 0
	}
	SubShader
	{

		Tags
		{
			"Queue" = "Geometry"
			"IgnoreProjector" = "True"
			"RenderType" = "Geometry"
		}

		Stencil
		{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}

		ZWrite On
		Lighting Off
		Fog { Mode Off }
		ZTest[unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask[_ColorMask]

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex TMP3D_VERT
			#pragma geometry TMP3D_GEOM_VARIANT
			#pragma fragment TMP3D_FRAG_UNLIT

			#pragma multi_compile _VOLUMEMODE_SURFACE _VOLUMEMODE_FULL

			#pragma require geometry

			#include "UnityCG.cginc"
			#include "TMPro_Properties.cginc"
			#include "TMP3D_Common.cginc"

			sampler2D _Gradient;
			float _RaymarchMinStep;

			struct fragOutput
			{
				fixed4 color : SV_Target;
				float depth : SV_Depth;
			};

			float compute_depth(float4 clippos)
			{
				#if defined(SHADER_TARGET_GLSL) || defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
				return ((clippos.z / clippos.w) + 1.0) * 0.5;
				#else
				return clippos.z / clippos.w;
				#endif
			}

			[maxvertexcount(24)]
			void TMP3D_GEOM_VARIANT(triangle tmp3d_v2g input[3], inout TriangleStream<tmp3d_g2f> triStream)
			{
				#if _VOLUMEMODE_SURFACE
				TMP3D_GEOM(input, triStream);
				#elif _VOLUMEMODE_FULL
				TMP3D_GEOM_INVERTED(input, triStream);
				#endif
			}

			fragOutput TMP3D_FRAG_UNLIT(tmp3d_g2f input)
			{
				UNITY_SETUP_INSTANCE_ID(input);

				fragOutput o;
				o.depth = 0;
				o.color = 0;
				fixed outline = 0;

				float c = tex2D(_MainTex, input.atlas).a;

				#if _VOLUMEMODE_SURFACE
				PrepareTMP3DRaymarch(input);
				#elif _VOLUMEMODE_FULL
				PrepareTMP3DRaymarchInverted(input);
				#endif

				float charDepth = input.tmp3d.x;
				float2 depthMapped = input.tmp3d.yz;

				for (int i = 0; i < 100; i++)
				{
					float3 localPos = GetRaymarchLocalPosition();
					float3 mask3D = PositionToMask(localPos, input);

					float bound = IsInBounds(mask3D);

					float value = -(SampleSDF3D(saturate(mask3D), input) * 2 - 1);

					if (value <= _OutlineWidth)
					{
						o.depth = compute_depth(mul(UNITY_MATRIX_VP, float4(GetRaymarchWorldPosition().xyz, 1)));
						o.color = _OutlineColor;
						outline = 1;
					}

					if (bound < 0 && outline > 0.5)
					{
						return o;
					}
					clip(bound);

					if (value <= 0)
					{
						float depth = -localPos.z;
						float progress = saturate(InverseLerp(0, charDepth, depth));
						progress = saturate(lerp(depthMapped.x, depthMapped.y, progress));
						float3 c = tex2D(_Gradient, float2(progress, 0.5));

						o.depth = compute_depth(mul(UNITY_MATRIX_VP, float4(GetRaymarchWorldPosition().xyz, 1)));
						o.color = float4(c.rgb * input.color, 1);
						return o;
					}

					float sdfDistance = max((value - lerp(_OutlineWidth, 0.01, outline)) * (GradientToLocalLength(input) * 0.5), _RaymarchMinStep);
					float3 viewDir = GetRaymarchLocalDirection();
					float length1 = length(normalize(viewDir.xy) * sdfDistance);
					float length2 = length(viewDir.xy);

					float ratio = length1 / length2;
					viewDir *= ratio;

					ProgressRaymarch(length(viewDir));
				}

				return o;
			}

			ENDCG
		}
	}
	Fallback "TextMeshPro/Mobile/Distance Field"
	CustomEditor "Ikaroon.TMP3DEditor.TMP3D_UnlitShaderGUI"
}
