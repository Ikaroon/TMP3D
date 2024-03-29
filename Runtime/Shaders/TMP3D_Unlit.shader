Shader "TextMeshPro/3D/Unlit"
{
	Properties
	{
		// General
		_FaceTex("Face Texture", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
		_WeightBold("Weight Bold", Range(0,1)) = 0.6
		_WeightNormal("Weight Normal", Range(0,1)) = 0.5

		// 3D
		_RaymarchMinStep("Raymarch min step", Range(0.001, 0.1)) = 0.01
		_RaymarchStepLength("Raymarch step length", Range(0.001, 1)) = 0.1
		_RaymarchBlueNoise("Raymarch Blue Noise", 2DArray) = "black" {}
		_RaymarchBlueNoise_Slices("Raymarch Blue Noise Slices", float) = 1
		_RaymarchBlueNoise_Speed("Raymarch Blue Noise Speed", float) = 10
		_RaymarchTemporalStepLength("Raymarch Temporal Step Length", Vector) = (0.01, 0.05, 0, 0)
		_DepthAlbedo("Depth Albedo", 2D) = "white" {}

		// Outline
		_OutlineColor("Outline Color", Color) = (0,0,0,1)
		_OutlineWidth("Outline Thickness", Range(0,1)) = 0
		_OutlineSoftness("Outline Softness", Range(0,1)) = 0

		// Font Atlas properties
		_MainTex("Font Atlas", 2D) = "white" {}
		_TextureWidth("Texture Width", float) = 512
		_TextureHeight("Texture Height", float) = 512
		_GradientScale("Gradient Scale", float) = 5.0
		_ScaleX("Scale X", float) = 1.0
		_ScaleY("Scale Y", float) = 1.0
		_PerspectiveFilter("Perspective Correction", Range(0, 1)) = 0.875
		_Sharpness("Sharpness", Range(-1,1)) = 0

		// TMP INTERNAL
		_ScaleRatioA("Scale Ratio A", float) = 1.0
		_ScaleRatioB("Scale Ratio B", float) = 1.0
		_ScaleRatioC("Scale Ratio C", float) = 1.0
	}
	SubShader
	{
		Tags
		{
			"Queue" = "Geometry"
			"IgnoreProjector" = "True"
			"RenderType" = "Geometry"
		}

		Lighting Off
		Fog { Mode Off }

		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			Stencil
			{
				Ref 2
				Comp Always
				Pass Replace
			}

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex TMP3D_VERT
			#pragma geometry TMP3D_GEOM_VARIANT
			#pragma fragment TMP3D_FRAG_UNLIT

			#pragma multi_compile __ OUTLINE_ON
			#pragma multi_compile _RAYMARCHER_SDF _RAYMARCHER_SIMPLE _RAYMARCHER_TEMPORAL
			#pragma multi_compile _MAXSTEPS_32 _MAXSTEPS_64 _MAXSTEPS_96 _MAXSTEPS_128
			#pragma multi_compile __ DEBUG_STEPS DEBUG_MASK

			#pragma require geometry

			#include "UnityCG.cginc"
			#include "Lib/TMP3D_Common.cginc"

			#if _RAYMARCHER_SDF
			#include "Lib/Raymarching/SDFMarcher.cginc"
			#elif _RAYMARCHER_SIMPLE
			#include "Lib/Raymarching/SimpleMarcher.cginc"
			#elif _RAYMARCHER_TEMPORAL
			#include "Lib/Raymarching/TemporalMarcher.cginc"
			#endif

			#if _MAXSTEPS_32
			#define MAX_STEPS 32
			#elif _MAXSTEPS_64
			#define MAX_STEPS 64
			#elif _MAXSTEPS_96
			#define MAX_STEPS 96
			#elif _MAXSTEPS_128
			#define MAX_STEPS 128
			#else
			#define MAX_STEPS 16
			#endif

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

			fragOutput ValidateOutput(fragOutput output, int step)
			{
				#if DEBUG_STEPS
				float stepDensity = (float)step / (float)MAX_STEPS;
				output.color = float4(stepDensity.x, 0, 0, 1);
				#elif DEBUG_MASK
				output.color = float4(GetRaymarchMask3D().xyz, 1);
				#endif
				return output;
			}

			fragOutput TMP3D_FRAG_UNLIT(tmp3d_g2f input)
			{
				UNITY_SETUP_INSTANCE_ID(input);

				fragOutput o;
				o.depth = 0;
				o.color = 0;

				float bold = step(input.tmp.y, 0);
				float edge = lerp(_WeightNormal, _WeightBold, bold);

				float charDepth = input.tmp3d.x;
				float2 depthMapped = input.tmp3d.yz;

				InitializeRaymarcher(input);

				for (int i = 0; i <= MAX_STEPS; i++)
				{
					NextRaymarch(edge);
					float3 localPos = GetRaymarchLocalPos();
					float bound = GetRaymarchBound();
					float value = GetRaymarchValue();
					float3 mask3D = GetRaymarchMask3D();

					//o.color = float4(value.xxx, 1);
					//return o;

					clip(bound);

					if (value <= edge)
					{
						float depth = -localPos.z;
						float progress = saturate(InverseLerp(0, charDepth, depth));
						progress = saturate(lerp(depthMapped.x, depthMapped.y, progress));
						float3 c = tex2D(_DepthAlbedo, float2(progress, 0.5)) * _Color.rgb;
						float3 face = tex2D(_FaceTex, localPos.xy * _FaceTex_ST.xy - _FaceTex_ST.zw);
						c *= face;

						o.depth = compute_depth(UnityObjectToClipPos(localPos));
						o.color = float4(c.rgb * input.color, 1);
						return ValidateOutput(o, i);
					}
				}

				clip(-1);
				return ValidateOutput(o, MAX_STEPS);
			}

			ENDCG
		}

		Pass
		{
			Stencil
			{
				Ref 2
				Comp NotEqual
			}

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex TMP3D_VERT_OUTLINE
			#pragma geometry TMP3D_GEOM_VARIANT
			#pragma fragment TMP3D_FRAG_UNLIT

			#pragma multi_compile __ OUTLINE_ON
			#pragma multi_compile _RAYMARCHER_SDF _RAYMARCHER_SIMPLE _RAYMARCHER_TEMPORAL
			#pragma multi_compile _MAXSTEPS_32 _MAXSTEPS_64 _MAXSTEPS_96 _MAXSTEPS_128
			#pragma multi_compile __ DEBUG_STEPS DEBUG_MASK

			#pragma require geometry

			#include "UnityCG.cginc"
			#include "Lib/TMP3D_Common.cginc"

			#if _RAYMARCHER_SDF
			#include "Lib/Raymarching/SDFMarcher.cginc"
			#elif _RAYMARCHER_SIMPLE
			#include "Lib/Raymarching/SimpleMarcher.cginc"
			#elif _RAYMARCHER_TEMPORAL
			#include "Lib/Raymarching/TemporalMarcher.cginc"
			#endif

			#if _MAXSTEPS_32
			#define MAX_STEPS 32
			#elif _MAXSTEPS_64
			#define MAX_STEPS 64
			#elif _MAXSTEPS_96
			#define MAX_STEPS 96
			#elif _MAXSTEPS_128
			#define MAX_STEPS 128
			#else
			#define MAX_STEPS 16
			#endif

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

			tmp3d_v2g TMP3D_VERT_OUTLINE(tmp3d_a2v input)
			{
				tmp3d_v2g output;

				output.position = mul(unity_ObjectToWorld, input.position);
				output.normal = mul(unity_ObjectToWorld, input.normal);
				output.color = input.color;
				output.texcoord0 = input.texcoord0;
				output.texcoord1 = input.texcoord1;
				output.texcoord2 = input.texcoord2;

				return output;
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

			fragOutput ValidateOutput(fragOutput output, int step)
			{
				#if DEBUG_STEPS
				float stepDensity = (float)step / (float)MAX_STEPS;
				output.color = float4(stepDensity.x, 0, 0, 1);
				#elif DEBUG_MASK
				output.color = float4(GetRaymarchMask3D().xyz, 1);
				#endif
				return output;
			}

			#if OUTLINE_ON

			fragOutput TMP3D_FRAG_UNLIT(tmp3d_g2f input)
			{
				UNITY_SETUP_INSTANCE_ID(input);

				fragOutput o;
				o.depth = 0;
				o.color = 0;

				float bold = step(input.tmp.y, 0);
				float edge = lerp(_WeightNormal, _WeightBold, bold);
				edge += _OutlineWidth;

				float charDepth = input.tmp3d.x;
				float2 depthMapped = input.tmp3d.yz;

				InitializeRaymarcher(input);

				for (int i = 0; i <= MAX_STEPS; i++)
				{
					NextRaymarch(edge);
					float3 localPos = GetRaymarchLocalPos();
					float bound = GetRaymarchBound();
					float value = GetRaymarchValue();
					float3 mask3D = GetRaymarchMask3D();

					if (value <= edge)
					{
						o.depth = compute_depth(UnityObjectToClipPos(localPos));
						o.color = _OutlineColor;
						return o;
					}

					clip(bound);
				}

				return ValidateOutput(o, MAX_STEPS);
			}

			#else

			fragOutput TMP3D_FRAG_UNLIT(tmp3d_g2f input)
			{
				UNITY_SETUP_INSTANCE_ID(input);

				clip(-1);
				
				fragOutput o;
				o.depth = 0;
				o.color = 0;
				return o;
			}

			#endif

			ENDCG
		}
	}
	CustomEditor "Ikaroon.TMP3DEditor.TMP3D_UnlitShaderGUI"
}
