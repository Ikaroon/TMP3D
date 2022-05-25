using UnityEngine;
using TMPro;
using System.Collections.Generic;

namespace Ikaroon.TMP3D
{
	[ExecuteInEditMode, RequireComponent(typeof(TextMeshPro))]
	public class TMP3D_Handler : MonoBehaviour
	{
		public TextMeshPro TMP { get { return m_tmp; } }
		[SerializeField, HideInInspector]
		TextMeshPro m_tmp;

		[SerializeField]
		float m_defaultDepth = 1;

		List<TMP3D_CharacterInfo> m_tmp3DCharacters = new List<TMP3D_CharacterInfo>();
		List<Vector4> m_cachedMeshUVs = new List<Vector4>();

		void OnEnable()
		{
			m_tmp = GetComponent<TextMeshPro>();

			// Subscribe to event fired when text object has been regenerated.
			TMPro_EventManager.TEXT_CHANGED_EVENT.Add(ON_TEXT_CHANGED);
		}

		void OnDisable()
		{
			TMPro_EventManager.TEXT_CHANGED_EVENT.Remove(ON_TEXT_CHANGED);
		}

		void ON_TEXT_CHANGED(Object obj)
		{
			if (obj != m_tmp || m_tmp == null)
				return;

			if (m_tmp.textInfo == null)
				return;

			// Remove old characters from 3D data
			for (int i = m_tmp3DCharacters.Count - 1; i >= m_tmp.textInfo.characterCount; i--)
			{
				m_tmp3DCharacters.RemoveAt(i);
			}

			// Add new characters to 3D data
			for (int i = m_tmp3DCharacters.Count; i < m_tmp.textInfo.characterCount; i++)
			{
				m_tmp3DCharacters.Add(new TMP3D_CharacterInfo(m_defaultDepth, new Vector2(0, 1)));
			}

			UpdateMeshValues();
		}

		public void SetDepth(int characterIndex, float depth)
		{
			var data = m_tmp3DCharacters[characterIndex];
			data.m_depth = depth;
			m_tmp3DCharacters[characterIndex] = data;
		}

		public void SetDepthMapping(int characterIndex, Vector2 depthMapping)
		{
			var data = m_tmp3DCharacters[characterIndex];
			data.m_depthMapping = depthMapping;
			m_tmp3DCharacters[characterIndex] = data;
		}

		public void UpdateMeshValues()
		{
			var count = Mathf.Min(m_tmp3DCharacters.Count, m_tmp.textInfo.characterCount);

			for (int i = 0; i < m_tmp.textInfo.meshInfo.Length; i++)
			{
				var meshInfo = m_tmp.textInfo.meshInfo[i];
				var mesh = meshInfo.mesh;

				if (mesh == null)
					continue;

				m_cachedMeshUVs.Clear();
				mesh.SetUVs(2, m_cachedMeshUVs);
				mesh.GetUVs(0, m_cachedMeshUVs);

				int lastVertexIndex = -1;
				for (int j = 0; j < count; j++)
				{
					var charInfo = m_tmp.textInfo.characterInfo[j];
					int meshIndex = charInfo.materialReferenceIndex;
					if (meshIndex != i)
						continue;

					int vertexIndex = charInfo.vertexIndex;

					if (lastVertexIndex > vertexIndex)
						continue;

					lastVertexIndex = vertexIndex;

					var tmp3DChar = m_tmp3DCharacters[j];
					var tmp3DData = new Vector4(tmp3DChar.m_depth, tmp3DChar.m_depthMapping.x, tmp3DChar.m_depthMapping.y, 0);

					m_cachedMeshUVs[vertexIndex + 0] = tmp3DData;
					m_cachedMeshUVs[vertexIndex + 1] = tmp3DData;
					m_cachedMeshUVs[vertexIndex + 2] = tmp3DData;
					m_cachedMeshUVs[vertexIndex + 3] = tmp3DData;
				}

				mesh.SetUVs(2, m_cachedMeshUVs);
			}
		}

		private void OnValidate()
		{
			m_tmp = GetComponent<TextMeshPro>();
			m_tmp3DCharacters.Clear();
			ON_TEXT_CHANGED(m_tmp);
		}
	}
}
