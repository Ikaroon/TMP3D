using UnityEditor;
using UnityEngine;

namespace Ikaroon.TMP3DEditor
{
	public class TMP3D_ShaderFeature
	{
		public string undoLabel;

		public GUIContent label;

		public GUIContent[] keywordLabels;

		public string[] keywords;

		int m_State;

		public int State
		{
			get { return m_State; }
		}

		public void ReadState(Material material)
		{
			for (int i = 0; i < keywords.Length; i++)
			{
				if (material.IsKeywordEnabled(keywords[i]))
				{
					m_State = i;
					return;
				}
			}

			m_State = 0;
			material.EnableKeyword(keywords[0]);
		}

		public void DoPopup(MaterialEditor editor, Material material)
		{
			EditorGUI.BeginChangeCheck();
			int selection = EditorGUILayout.Popup(label, m_State, keywordLabels);
			if (EditorGUI.EndChangeCheck())
			{
				m_State = selection;
				editor.RegisterPropertyChangeUndo(undoLabel);
				SetStateKeywords(material);
			}
		}

		void SetStateKeywords(Material material)
		{
			for (int i = 0; i < keywords.Length; i++)
			{
				if (i == m_State)
				{
					material.EnableKeyword(keywords[i]);
				}
				else
				{
					material.DisableKeyword(keywords[i]);
				}
			}
		}
	}
}
