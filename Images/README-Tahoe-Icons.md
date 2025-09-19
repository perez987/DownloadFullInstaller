# Tahoe-Style Icons with Liquid Glass Effects

This folder contains new Tahoe-style app icons created based on the original `Appicon-light.icns`.

## New Icon Files

### Variant 1 - Cool Glass Effect
- **File**: `Appicon-tahoe-variant1.icns`
- **Preview**: `tahoe_icon_variant1.png`
- **Style**: Subtle blue tint with cool glass effect
- **Features**: 
  - Ultra-thin material background
  - 16px rounded corners (Tahoe standard)
  - Quaternary stroke with 0.8 opacity
  - Subtle shadow (radius: 12, offset: 4)
  - Cool blue glass tint

### Variant 2 - Warm Glass Effect  
- **File**: `Appicon-tahoe-variant2.icns`
- **Preview**: `tahoe_icon_variant2.png`
- **Style**: Enhanced contrast with warm glass effect
- **Features**:
  - Ultra-thin material background
  - 16px rounded corners (Tahoe standard)
  - Quaternary stroke with 0.8 opacity  
  - Subtle shadow (radius: 12, offset: 4)
  - Warm white glass tint
  - Enhanced contrast (1.15x)

## Implementation Details

The icons follow the Liquid Glass specifications from `LiquidGlassStyle.swift`:

```swift
// macOS 26+: Advanced container effects
content
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    .overlay(
        RoundedRectangle(cornerRadius: 16)
            .stroke(.quaternary.opacity(0.8), lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
```

## Usage

To use one of these icons as the new app icon:

1. Choose between Variant 1 (cool) or Variant 2 (warm)
2. Replace the current app icon files in the Xcode project
3. Update the bundle to reference the new icon

## Original Source

Based on `Appicon-light.icns` (1024x1024px) from the main branch of perez987/DownloadFullInstaller repository.