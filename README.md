<p align=center><img alt="TMP3D Logo" width="400px" src="https://user-images.githubusercontent.com/65419234/167305638-76138392-b394-4e1e-b391-d59677b61762.png"/></p>

<p align=center><a href="https://github.com/Ikaroon/com.ikaroon.tmp3d/blob/master/LICENSE"><img src="https://badgen.net/github/license/Naereen/Strapdown.js"/></a>
<a href="https://GitHub.com/Ikaroon/com.ikaroon.tmp3d/releases/"><img src="https://img.shields.io/badge/release-0.1.0--pre.1-yellow.svg"/></a>
<img alt="GitHub (Pre-)Release Date" src="https://img.shields.io/github/release-date-pre/Ikaroon/TMP3D"></p>

# Text Mesh Pro 3D
An extension for Text Mesh Pro that makes 3D text possible using shaders.

## Features
- [x] Solid, unlit shader (3D)
- [x] 3D character properties and animation
- [x] Outline support
- [x] Bold text support
- [x] Italic text support
- [x] Debug rendering
- [ ] Solid, surface shader
- [ ] Solid, unlit shader (UI)
- [ ] Documentation

### In Evaluation
- [ ] Bevelled text[^1]
- [ ] Full fledged freeform text using textures[^1]
- [ ] Translucent, unlit shader
- [ ] VR optimizations[^2]

[^1]: Tempering with the SDF values in the distance makes raymarching more difficult, I need to find a good way of evaluating the shortest distance.
[^2]: I currently don't have access to any VR device and, therefore, cannot optimize for it right now.

## Compatibility

| Graphics API  | Built-in                        | HDRP                            | URP                             |
|---------------|---------------------------------|---------------------------------|---------------------------------|
| DirectX 11    | :heavy_check_mark: Compatible   | :heavy_check_mark: Compatible   | :heavy_check_mark: Compatible   |
| DirectX 12    | :heavy_check_mark: Compatible   | :heavy_check_mark: Compatible   | :heavy_check_mark: Compatible   |
| Vulkan        | :heavy_check_mark: Compatible   | :heavy_check_mark: Compatible   | :heavy_check_mark: Compatible   |
| OpenGL Core   | :heavy_check_mark: Compatible   | :warning: Invalid               | :heavy_check_mark: Compatible   |
| OpenGLES2[^3] | :x: Incompatible                | :warning: Invalid               | :x: Incompatible                |
| OpenGLES3     | :heavy_check_mark: Compatible   | :warning: Invalid               | :heavy_check_mark: Compatible   |
| Metal[^4]     | :wavy_dash: To Be Tested        | :wavy_dash: To Be Tested        | :wavy_dash: To Be Tested        |

[^3]: Support for OpenGLES2 is currently **NOT** planned.
[^4]: I currently don't have access to any Mac and, therefore, cannot test it for Metal right now.

If the shader doesn't work for a compatible combination try to reimport the shader file first!
When the issue persists contact me!

## Installation

![PackageInstallation](https://user-images.githubusercontent.com/65419234/167270188-99300531-ec7e-45ea-89d9-612ec1d37eaf.png)
1. Open the package manager in Unity from `Window>Package Manager`
2. Select the `+` dropdown button in the top-left corner of the package manager
3. Select `Add package from git URL...`
4. Enter `https://github.com/Ikaroon/TMP3D.git` as url and confirm

This method will always install the current state of the git. To get a released version head to the [release page](https://github.com/Ikaroon/TMP3D/releases)!

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
If this project helped you, you can treat me to a coffee if you want :coffee:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/B0B1CKI7W)

## Contact
If you need support with this package please contact me: `support@marian-brinkmann.com`
