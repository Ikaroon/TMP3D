using UnityEngine;
using UnityEditor;
using TMPro.EditorUtilities;
using TMPro;

namespace Ikaroon.TMP3DEditor
{
	public class TMP3D_UnlitShaderGUI : TMP_BaseShaderGUI
	{
		static ShaderFeature s_outlineFeature;
		static TMP3D_ShaderFeature s_volumeModeFeature;
		static TMP3D_ShaderFeature s_raymarchModeFeature;
		static TMP3D_ShaderFeature s_maxStepsFeature;
		static ShaderFeature s_debugFeature;

		static bool s_general = true;
		static bool s_outline = true;
		static bool s_3D = true;

		static TMP3D_UnlitShaderGUI()
		{
			s_outlineFeature = new ShaderFeature()
			{
				undoLabel = "Outline",
				keywords = new[] { "OUTLINE_ON" }
			};
			s_volumeModeFeature = new TMP3D_ShaderFeature()
			{
				undoLabel = "VolumeMode",
				label = new GUIContent("Volume Mode"),
				keywords = new[] { "_VOLUMEMODE_SURFACE", "_VOLUMEMODE_FULL" },
				keywordLabels = new[] { new GUIContent("Surface"), new GUIContent("Full") }
			};
			s_raymarchModeFeature = new TMP3D_ShaderFeature()
			{
				undoLabel = "RaymarchMode",
				label = new GUIContent("Raymarch Mode"),
				keywords = new[] { "_RAYMARCHER_STANDARD", "_RAYMARCHER_PENALTY" },
				keywordLabels = new[] { new GUIContent("Standard"), new GUIContent("Penalty") }
			};
			s_maxStepsFeature = new TMP3D_ShaderFeature()
			{
				undoLabel = "MaxSteps",
				label = new GUIContent("Max Steps"),
				keywords = new[] { "_MAXSTEPS_32", "_MAXSTEPS_64", "_MAXSTEPS_96", "_MAXSTEPS_128" },
				keywordLabels = new[] { new GUIContent("32"), new GUIContent("64"), new GUIContent("96"), new GUIContent("128") }
			};
			s_debugFeature = new ShaderFeature()
			{
				undoLabel = "Debug",
				label = new GUIContent("Debug Mode"),
				keywords = new[] { "DEBUG_STEPS", "DEBUG_MASK" },
				keywordLabels = new[] { new GUIContent("None"), new GUIContent("Steps"), new GUIContent("Mask") }
			};
		}

		protected override void DoGUI()
		{
			s_general = BeginPanel("General", s_general);
			if (s_general)
			{
				DoGeneralPanel();
			}

			EndPanel();

			s_3D = BeginPanel("3D", s_3D);
			if (s_3D)
			{
				Do3DPanel();
			}

			EndPanel();

			s_outline = BeginPanel("Outline", s_outlineFeature, s_outline);
			if (s_outline)
			{
				DoOutlinePanel();
			}

			EndPanel();

			s_DebugExtended = BeginPanel("Debug Settings", s_DebugExtended);
			if (s_DebugExtended)
			{
				DoDebugPanel();
			}

			EndPanel();
		}

		void DoGeneralPanel()
		{
			EditorGUI.indentLevel += 1;

			DoColor("_Color", "Color");
			DoSlider("_WeightBold", "Weight Bold");
			DoSlider("_WeightNormal", "Weight Normal");

			EditorGUI.indentLevel -= 1;
			EditorGUILayout.Space();
		}

		void DoOutlinePanel()
		{
			EditorGUI.indentLevel += 1;
			DoColor("_OutlineColor", "Color");
			DoSlider("_OutlineWidth", "Thickness");

			EditorGUI.indentLevel -= 1;
			EditorGUILayout.Space();
		}

		void Do3DPanel()
		{
			EditorGUI.indentLevel += 1;

			s_volumeModeFeature.ReadState(m_Material);
			s_raymarchModeFeature.ReadState(m_Material);
			s_maxStepsFeature.ReadState(m_Material);

			s_volumeModeFeature.DoPopup(m_Editor, m_Material);
			s_raymarchModeFeature.DoPopup(m_Editor, m_Material);
			s_maxStepsFeature.DoPopup(m_Editor, m_Material);

			DoSlider("_RaymarchMinStep", "Min Step");
			DoTexture2D("_DepthAlbedo", "Depth Albedo");

			EditorGUI.indentLevel -= 1;
			EditorGUILayout.Space();
		}

		void DoDebugPanel()
		{
			EditorGUI.indentLevel += 1;
			DoTexture2D("_MainTex", "Font Atlas");
			DoFloat("_GradientScale", "Gradient Scale");
			DoFloat("_TextureWidth", "Texture Width");
			DoFloat("_TextureHeight", "Texture Height");
			s_debugFeature.ReadState(m_Material);
			s_debugFeature.DoPopup(m_Editor, m_Material);
			EditorGUI.indentLevel -= 1;
			EditorGUILayout.Space();
		}
	}
}
