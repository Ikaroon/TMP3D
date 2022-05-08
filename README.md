![TMP3D](https://user-images.githubusercontent.com/65419234/167267289-79726275-a87c-4f8e-a370-eb0b28c0036f.png)

<p align=center><a href="https://github.com/Ikaroon/com.ikaroon.tmp3d/blob/master/LICENSE"><img src="https://badgen.net/github/license/Naereen/Strapdown.js"/></a>
<a href="https://GitHub.com/Ikaroon/com.ikaroon.tmp3d/releases/"><img src="https://img.shields.io/badge/Release-0.1.0--pre.1-yellow.svg"/></a>
<a href="https://ko-fi.com/ikaroon"><img src="https://img.shields.io/badge/Donate-Ko--Fi-red.svg"/></a></p>

# Text Mesh Pro 3D
An extension for Text Mesh Pro that makes 3D text possible using shaders.

## Features
- [x] Solid, unlit shader (3D)
- [x] 3D character properties and animation
- [x] Outline support
- [ ] Italic text support
- [ ] Bold text support
- [ ] Solid, surface shader
- [ ] Solid, unlit shader (UI)
- [ ] Documentation

### In Evaluation
- [ ] Bevelled text
- [ ] Full fledged freeform text using textures
- [ ] Translucent, unlit shader
- [ ] VR optimizations

## Installation

![PackageInstallation](https://user-images.githubusercontent.com/65419234/167270188-99300531-ec7e-45ea-89d9-612ec1d37eaf.png)
1. Open the package manager in Unity from `Window>Package Manager`
2. Select the `+` dropdown button in the top-left corner of the package manager
3. Select `Add package from git URL...`
4. Enter `https://github.com/Ikaroon/TMP3D.git` as url and confirm

## How to use
To understand how to setup a TextMeshPro for 3D you can check out the sample in the package. For downloading that follow these steps:
1. Open the package manager in Unity from `Window>Package Manager`
2. Select `Text Mesh Pro 3D Support` in the section `Ikaroon`
3. Expand `Samples`
4. Click `Import` next to `Solid Text`
5. Now open the scene from `Assets/Samples/Text Mesh Pro 3D Support/<version>/Solid Text/Scenes/Sample_TMP3D`

If you still need help, here are some steps how you setup a TextMeshPro for 3D:
1. Create a new FontAsset by using the `Font Asset Creator` from `Window>Text Mesh Pro>Font Asset Creator`
2. Expand the created Asset and select the Material
3. Change the Material's shader to `TextMeshPro/3D/Unlit`
4. Create a TextMeshPro in a scene from `3D Object>Text - TextMeshPro` NOT from `UI>Text - TextMeshPro` this is not supported yet.
5. Add a TMP3D_Handler component from `Script>Ikaroon.TMP3D>TMP3D_Handler`
6. Apply the FontAsset to the TextMeshPro component
7. You have now acces to 3D text!

## Notice
Work on this project happens in my freetime and, therefore, I cannot promise if and when certain features are added. I am considering to open this up for contribution but for now you can manipulate the code as you please. This project is MIT licensed and may be used freely. (Check the license file for more information)

## Donation
If this project helped you, you can treat me to a coffee if you want ☕

[![Donate](https://img.shields.io/badge/Donate-Ko--Fi-red.svg)](https://ko-fi.com/ikaroon)
