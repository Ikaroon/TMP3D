using UnityEngine;
using UnityEditor;
using TMPro.EditorUtilities;

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

		protected static GUIContent s_tempLabel = new GUIContent();

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
				keywords = new[] { "_RAYMARCHER_SDF", "_RAYMARCHER_SIMPLE", "_RAYMARCHER_TEMPORAL" },
				keywordLabels = new[] { new GUIContent("Signed Distance Field"), new GUIContent("Simple"), new GUIContent("Temporal") }
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

		protected MaterialProperty BeginProperty(string name)
		{
			MaterialProperty property = FindProperty(name, m_Properties);
			EditorGUI.BeginChangeCheck();
			EditorGUI.showMixedValue = property.hasMixedValue;
			m_Editor.BeginAnimatedCheck(Rect.zero, property);

			return property;
		}

		protected bool EndProperty()
		{
			m_Editor.EndAnimatedCheck();
			EditorGUI.showMixedValue = false;
			return EditorGUI.EndChangeCheck();
		}

		protected void DoMinMaxSlider(string property, string label, float minLimit, float maxLimit, int indexA, int indexB)
		{
			MaterialProperty prop = BeginProperty(property);
			s_tempLabel.text = label;

			var vector = prop.vectorValue;
			var min = vector[indexA];
			var max = vector[indexB];

			float originalValue = EditorGUIUtility.labelWidth;
			EditorGUIUtility.labelWidth = originalValue - 26;

			EditorGUILayout.BeginHorizontal();
			EditorGUILayout.PrefixLabel(s_tempLabel);
			min = EditorGUILayout.FloatField(min, GUILayout.Width(100f));
			EditorGUILayout.MinMaxSlider(ref min, ref max, minLimit, maxLimit);
			max = EditorGUILayout.FloatField(max, GUILayout.Width(100f));
			min = Mathf.Clamp(min, minLimit, max);
			max = Mathf.Clamp(max, min, maxLimit);
			EditorGUILayout.EndHorizontal();

			EditorGUIUtility.labelWidth = originalValue;

			if (EndProperty())
			{
				vector[indexA] = min;
				vector[indexB] = max;
				prop.vectorValue = vector;
				m_Editor.RegisterPropertyChangeUndo(label);
			}
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
			DoTexture2D("_FaceTex", "Face Texture", true);

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

			switch (s_raymarchModeFeature.State)
			{
				case 0:
					DoSlider("_RaymarchMinStep", "Min Step");
					break;
				case 1:
					DoSlider("_RaymarchStepLength", "Step Length");
					break;
				case 2:
					DoMinMaxSlider("_RaymarchTemporalStepLength", "Step Length", 0, 1, 0, 1);
					var texture = m_Editor.TextureProperty(FindProperty("_RaymarchBlueNoise", m_Properties), "Blue Noise", false) as Texture2DArray;
					if (texture != null)
					{
						FindProperty("_RaymarchBlueNoise_Slices", m_Properties).floatValue = texture.depth;
					}
					DoFloat("_RaymarchBlueNoise_Speed", "Blue Noise Speed");
					break;
			}
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
