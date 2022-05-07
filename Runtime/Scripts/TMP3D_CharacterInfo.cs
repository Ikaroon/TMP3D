using UnityEngine;

namespace Ikaroon.TMP3D
{
	public struct TMP3D_CharacterInfo
	{
		public float m_depth;
		public Vector2 m_depthMapping;

		public TMP3D_CharacterInfo(float depth, Vector2 depthMapping)
		{
			m_depth = depth;
			m_depthMapping = depthMapping;
		}
	}
}
