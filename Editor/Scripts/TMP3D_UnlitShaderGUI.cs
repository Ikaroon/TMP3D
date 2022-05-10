using UnityEngine;
using UnityEditor;
using TMPro.EditorUtilities;
using TMPro;

namespace Ikaroon.TMP3DEditor
{
	public class TMP3D_UnlitShaderGUI : TMP_BaseShaderGUI
	{
		public enum VolumeMode
		{
			Surface,
			Full
		}

		static ShaderFeature s_OutlineFeature;

		static bool s_Face = true;
		static bool s_Outline = true;
		static bool s_Raymarch = true;

		const string c_volumeModeSurface = "_VOLUMEMODE_SURFACE";
		const string c_volumeModeFull = "_VOLUMEMODE_FULL";

		static TMP3D_UnlitShaderGUI()
		{
			s_OutlineFeature = new ShaderFeature()
			{
				undoLabel = "Outline",
				keywords = new[] { "OUTLINE_ON" }
			};
		}

		VolumeMode GetVolumeMode(Material material)
		{
			if (material.IsKeywordEnabled(c_volumeModeSurface))
				return VolumeMode.Surface;

			if (material.IsKeywordEnabled(c_volumeModeFull))
				return VolumeMode.Full;

			material.EnableKeyword(c_volumeModeSurface);
			return VolumeMode.Surface;
		}

		protected override void DoGUI()
		{
			s_Face = BeginPanel("Face", s_Face);
			if (s_Face)
			{
				DoFacePanel();
			}

			EndPanel();

			s_Outline = BeginPanel("Outline", s_OutlineFeature, s_Outline);
			if (s_Outline)
			{
				DoOutlinePanel();
			}

			EndPanel();

			s_Raymarch = BeginPanel("Raymarch", s_Raymarch);
			if (s_Raymarch)
			{
				DoRaymarchPanel();
			}

			EndPanel();

			s_DebugExtended = BeginPanel("Debug Settings", s_DebugExtended);
			if (s_DebugExtended)
			{
				DoDebugPanel();
			}

			EndPanel();
		}

		void DoFacePanel()
		{
			EditorGUI.indentLevel += 1;

			DoColor("_FaceColor", "Color");

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

		void DoRaymarchPanel()
		{
			EditorGUI.indentLevel += 1;

			var mode = GetVolumeMode(m_Material);
			var targetMode = (VolumeMode)EditorGUILayout.EnumPopup(new GUIContent("Volume Mode"), mode);
			if (targetMode != mode)
			{
				switch (targetMode)
				{
					case VolumeMode.Surface:
						m_Material.EnableKeyword(c_volumeModeSurface);
						m_Material.DisableKeyword(c_volumeModeFull);
						break;
					case VolumeMode.Full:
						m_Material.EnableKeyword(c_volumeModeFull);
						m_Material.DisableKeyword(c_volumeModeSurface);
						break;
				}
			}

			DoSlider("_RaymarchMinStep", "Min Step");

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
			EditorGUILayout.Space();
			DoFloat("_ScaleX", "Scale X");
			DoFloat("_ScaleY", "Scale Y");

			DoSlider("_PerspectiveFilter", "Perspective Filter");
			EditorGUILayout.Space();
			DoFloat("_VertexOffsetX", "Offset X");
			DoFloat("_VertexOffsetY", "Offset Y");

			EditorGUILayout.Space();

			EditorGUI.BeginDisabledGroup(true);
			DoFloat("_ScaleRatioA", "Scale Ratio A");
			DoFloat("_ScaleRatioB", "Scale Ratio B");
			DoFloat("_ScaleRatioC", "Scale Ratio C");
			EditorGUI.EndDisabledGroup();
			EditorGUI.indentLevel -= 1;
			EditorGUILayout.Space();
		}
	}
}
