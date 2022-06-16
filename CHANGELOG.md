# Changelog
All notable changes to this project will be documented in this file.

## [Unreleased]
### Added
- Support for face texture rendering
- Support for underlined text rendering
- Support for strikethrough text rendering

### Changed
- Improved Temporal Raymarcher quality
- Reduced "if"-usage but doubled pass
- Slightly improved SDF raymarcher quality and performance
- Slightly improved outline quality

## [v0.1.1] - 2022-05-27
### Added
- Simple Raymarcher
- Temporal Raymarcher optimized for Temporal Antialiasing
- One click creation of TMP3D GameObject
- Font Asset conversion via the TMP3D_Handler

### Changed
- Renamed Standard Raymarcher to SDF Raymarcher

### Fixed
- Fix ArgumentOutOfRangeException when text is empty
- Fix "Full" raymarch mode creates slits in geometry
- Fix "Full" raymarch mode does not support italic text

## [v0.1.0] - 2022-05-13
### Added
- Support for bold text rendering
- Support for italic text rendering
- Custom Shader GUI for easier material editing
- Raymarching options for more control
- Support for more raymarching algorithms for the future
- Debug options to show used steps and the 3D uvs

### Changed
- Raymarching usage for more control and new algorithms in the future
- Boundaries structure for raymarching
- Outline rendering is now a shader feature and can be fully disabled

### Removed
- Unused shader uniforms

## [v0.1.0-pre.1] - 2022-05-08
### Added
- Solid, unlit shader
- Basic raymarching support
- Support for character manipulation for animations
- Support for outline rendering
