using Ikaroon.TMP3D;
using TMPro;
using UnityEditor;
using UnityEngine;

namespace Ikaroon.TMP3DEditor
{
	public static class TMP3D_MenuItems
	{
		[MenuItem("GameObject/3D Object/Text - TextMeshPro (3D)", false)]
		public static void CreateTMP3D(MenuCommand menuCommand)
		{
			GameObject go = new GameObject("Text (TMP3D)");
			GameObjectUtility.SetParentAndAlign(go, menuCommand.context as GameObject);

			var tmp = go.AddComponent<TextMeshPro>();
			tmp.font = TMP3D_Data.DEFAULT_FONT_ASSET;
			tmp.text = "Sample text";

			go.AddComponent<TMP3D_Handler>();

			Undo.RegisterCreatedObjectUndo(go, "Create " + go.name);
			Selection.activeObject = go;
		}
	}
}
