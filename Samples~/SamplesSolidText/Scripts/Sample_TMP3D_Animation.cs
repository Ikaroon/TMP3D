using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Ikaroon.TMP3D.Demo
{
	public class Sample_TMP3D_Animation : MonoBehaviour
	{
		public enum Mode
		{
			Time,
			Manual
		}
		[SerializeField]
		Mode m_mode;

		[SerializeField]
		float m_manual = 0f;

		[SerializeField]
		Vector2 m_minMax = new Vector2(0.1f, 1f);
		[SerializeField]
		float m_offset = 0.1f;
		[SerializeField]
		float m_speed = 2f;

		[SerializeField]
		TMP3D_Handler m_tmp3DHandler;

		void Update()
		{
			float time = 0f;
			switch (m_mode)
			{
				case Mode.Time:
					time = Time.time;
					break;
				case Mode.Manual:
					time = m_manual;
					break;
			}

			var tmp = m_tmp3DHandler.TMP;
			for (int i = 0; i < tmp.textInfo.characterCount; i++)
			{
				var charInfo = tmp.textInfo.characterInfo[i];

				var depth = Mathf.Lerp(m_minMax.x, m_minMax.y, Mathf.Sin(((float)(i) * m_offset) - time * Mathf.PI * m_speed) * 0.5f + 0.5f);
				m_tmp3DHandler.SetDepth(i, depth);
				m_tmp3DHandler.SetDepthMapping(i, new Vector2(0, depth / m_minMax.y));
			}
			m_tmp3DHandler.UpdateMeshValues();
		}
	}
}
