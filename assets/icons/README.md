# App Icon Generation Guide

This directory contains the design specifications and tools for generating the Neon Pulse app icons.

## Quick Start

### Option 1: Using the Python Script (Recommended)

1. Install required dependencies:
   ```bash
   pip install Pillow
   ```

2. Run the icon generation script:
   ```bash
   cd scripts
   python generate_icons.py
   ```

This will automatically generate all required icon sizes for both Android and iOS platforms.

### Option 2: Manual Generation from SVG

1. Use the `app_icon_template.svg` as a base design
2. Convert to PNG at required sizes using a tool like Inkscape or online converters
3. Place the generated files in the appropriate platform directories

## Required Icon Sizes

### Android (Adaptive Icons)
- `mipmap-mdpi/ic_launcher.png` - 48x48px
- `mipmap-hdpi/ic_launcher.png` - 72x72px  
- `mipmap-xhdpi/ic_launcher.png` - 96x96px
- `mipmap-xxhdpi/ic_launcher.png` - 144x144px
- `mipmap-xxxhdpi/ic_launcher.png` - 192x192px

Plus foreground and background variants for adaptive icons.

### iOS
- Various sizes from 20x20 to 1024x1024 (see script for complete list)
- Files go in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Design Guidelines

- **Theme**: Cyberpunk with neon effects
- **Colors**: Electric blue (#00FFFF), hot pink (#FF1493), neon green (#39FF14)
- **Background**: Dark space (#0B0B1F) with purple gradient (#1A0B2E)
- **Elements**: Geometric bird silhouette with particle trail and glow effects

## Verification

After generating icons:

1. Build the app for your target platform
2. Check that the icon appears correctly on the home screen
3. Verify the icon looks good at different sizes and themes (light/dark mode)
4. Test on different devices to ensure proper scaling

## Troubleshooting

- **Icons not updating**: Clean and rebuild the project
- **Blurry icons**: Ensure you're using the correct pixel dimensions
- **Missing icons**: Check that all required sizes are generated
- **Android adaptive issues**: Verify the foreground/background separation

## Files in this Directory

- `app_icon_design.md` - Design specification and requirements
- `app_icon_template.svg` - SVG template for manual conversion
- `README.md` - This file
- `../scripts/generate_icons.py` - Automated icon generation script