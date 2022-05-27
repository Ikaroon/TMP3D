using System.IO;
using TMPro;
using UnityEditor;
using UnityEngine;

namespace Ikaroon.TMP3DEditor
{
	internal static class TMP3D_Data
	{
		public const string SHADER_NAME_SPACE = "TextMeshPro/3D";
		public const string DEFAULT_SHADER_NAME = "TextMeshPro/3D/Unlit";

		public static TMP_FontAsset DEFAULT_FONT_ASSET
		{
			get
			{
				return AssetDatabase.LoadAssetAtPath<TMP_FontAsset>("Packages/com.ikaroon.tmp3d/Runtime/Data/Fonts & Materials/LiberationSans SDF (3D).asset");
			}
		}

		public static void ApplyDefaultMaterialData(Material material)
		{
			material.SetFloat("_WeightNormal", 0.5f);
			material.SetFloat("_WeightBold", 0.65f);
		}

		public static TMP_FontAsset ConvertFontAssetTo3D(TMP_FontAsset fontAsset)
		{
			var path = AssetDatabase.GetAssetPath(fontAsset);
			var ext = Path.GetExtension(path);
			var dir = Path.GetDirectoryName(path);
			var file = Path.GetFileNameWithoutExtension(path);
			var newPath = $"{dir}/{file} (3D){ext}";
			if (!AssetDatabase.CopyAsset(path, newPath))
			{
				throw new IOException($"[TMP3D] Failed to create a 3D cope of {path} as {newPath}");
			}
			AssetDatabase.SaveAssets();

			var newFontAsset = AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(newPath);
			newFontAsset.material.shader = Shader.Find(DEFAULT_SHADER_NAME);
			ApplyDefaultMaterialData(newFontAsset.material);

			return newFontAsset;
		}
	}
}
