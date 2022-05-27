using Ikaroon.TMP3D;
using UnityEditor;
using UnityEngine;

namespace Ikaroon.TMP3DEditor
{
	[CustomEditor(typeof(TMP3D_Handler))]
	public class TMP3D_HandlerEditor : Editor
	{
		TMP3D_Handler m_handler;

		private void OnEnable()
		{
			m_handler = (TMP3D_Handler)target;
		}

		public override void OnInspectorGUI()
		{
			EditorGUILayout.PropertyField(serializedObject.FindProperty("m_defaultDepth"));
			serializedObject.ApplyModifiedProperties();

			var fontAsset = m_handler.TMP.font;
			EditorGUI.BeginDisabledGroup(fontAsset.material.shader.name.Contains(TMP3D_Data.SHADER_NAME_SPACE));
			if (GUILayout.Button(new GUIContent("Create 3D Font Asset Variant")))
			{
				Undo.RecordObject(m_handler.TMP, "Converted Font Asset to 3D");
				var newFont = TMP3D_Data.ConvertFontAssetTo3D(fontAsset);
				m_handler.TMP.font = newFont;
			}
			EditorGUI.EndDisabledGroup();
		}
	}
}
