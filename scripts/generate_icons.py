#!/usr/bin/env python3
"""
Icon Generation Script for Neon Pulse Flappy Bird
This script generates all required app icons for Android and iOS platforms.
"""

from PIL import Image, ImageDraw, ImageFilter
import os
import math

# Color palette
COLORS = {
    'background': '#0B0B1F',
    'gradient': '#1A0B2E', 
    'primary_neon': '#00FFFF',
    'secondary_neon': '#FF1493',
    'accent_neon': '#39FF14'
}

def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def create_neon_bird_icon(size):
    """Create a cyberpunk-themed bird icon with neon effects"""
    # Create image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Create background gradient
    for y in range(size):
        ratio = y / size
        bg_color = blend_colors(COLORS['background'], COLORS['gradient'], ratio)
        draw.line([(0, y), (size, y)], fill=bg_color)
    
    # Draw bird silhouette (simplified geometric shape)
    center_x, center_y = size // 2, size // 2
    bird_size = size * 0.6
    
    # Bird body (oval)
    body_left = center_x - bird_size * 0.3
    body_top = center_y - bird_size * 0.2
    body_right = center_x + bird_size * 0.2
    body_bottom = center_y + bird_size * 0.2
    
    # Draw bird with neon glow effect
    draw.ellipse([body_left, body_top, body_right, body_bottom], 
                fill=hex_to_rgb(COLORS['primary_neon']))
    
    # Bird beak (triangle)
    beak_points = [
        (body_right, center_y - bird_size * 0.05),
        (body_right + bird_size * 0.15, center_y),
        (body_right, center_y + bird_size * 0.05)
    ]
    draw.polygon(beak_points, fill=hex_to_rgb(COLORS['secondary_neon']))
    
    # Bird tail (triangle)
    tail_points = [
        (body_left, center_y - bird_size * 0.1),
        (body_left - bird_size * 0.2, center_y - bird_size * 0.15),
        (body_left - bird_size * 0.15, center_y + bird_size * 0.05),
        (body_left, center_y + bird_size * 0.1)
    ]
    draw.polygon(tail_points, fill=hex_to_rgb(COLORS['accent_neon']))
    
    # Add particle trail effect
    for i in range(5):
        particle_x = body_left - bird_size * 0.3 - i * size * 0.05
        particle_y = center_y + (i % 2 - 0.5) * size * 0.1
        particle_size = max(2, size * 0.02 - i)
        
        if particle_x > 0:
            draw.ellipse([particle_x - particle_size, particle_y - particle_size,
                         particle_x + particle_size, particle_y + particle_size],
                        fill=hex_to_rgb(COLORS['primary_neon']))
    
    # Apply glow effect
    img = apply_glow_effect(img)
    
    return img

def blend_colors(color1, color2, ratio):
    """Blend two hex colors with given ratio"""
    rgb1 = hex_to_rgb(color1)
    rgb2 = hex_to_rgb(color2)
    
    blended = tuple(int(rgb1[i] * (1 - ratio) + rgb2[i] * ratio) for i in range(3))
    return blended

def apply_glow_effect(img):
    """Apply neon glow effect to the image"""
    # Create a copy for the glow
    glow = img.copy()
    
    # Apply blur for glow effect
    glow = glow.filter(ImageFilter.GaussianBlur(radius=3))
    
    # Composite the glow behind the original
    result = Image.new('RGBA', img.size, (0, 0, 0, 0))
    result = Image.alpha_composite(result, glow)
    result = Image.alpha_composite(result, img)
    
    return result

def generate_android_icons():
    """Generate Android adaptive icons"""
    android_sizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192
    }
    
    base_path = '../android/app/src/main/res'
    
    for density, size in android_sizes.items():
        # Create directory if it doesn't exist
        dir_path = f'{base_path}/mipmap-{density}'
        os.makedirs(dir_path, exist_ok=True)
        
        # Generate icon
        icon = create_neon_bird_icon(size)
        icon.save(f'{dir_path}/ic_launcher.png')
        
        # Also create foreground and background for adaptive icons
        # Background (solid color)
        bg = Image.new('RGBA', (size, size), hex_to_rgb(COLORS['background']))
        bg.save(f'{dir_path}/ic_launcher_background.png')
        
        # Foreground (bird with transparent background)
        fg = create_neon_bird_icon(size)
        fg.save(f'{dir_path}/ic_launcher_foreground.png')
        
        print(f'Generated Android {density} icons ({size}x{size})')

def generate_ios_icons():
    """Generate iOS app icons"""
    ios_sizes = {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024
    }
    
    base_path = '../ios/Runner/Assets.xcassets/AppIcon.appiconset'
    
    for filename, size in ios_sizes.items():
        icon = create_neon_bird_icon(size)
        icon.save(f'{base_path}/{filename}')
        print(f'Generated iOS icon {filename} ({size}x{size})')

def main():
    """Main function to generate all icons"""
    print("Generating Neon Pulse Flappy Bird App Icons...")
    print("=" * 50)
    
    try:
        generate_android_icons()
        print()
        generate_ios_icons()
        print()
        print("✅ All icons generated successfully!")
        print("Note: Make sure to update AndroidManifest.xml and Info.plist with proper app names.")
        
    except Exception as e:
        print(f"❌ Error generating icons: {e}")
        print("Make sure you have Pillow installed: pip install Pillow")

if __name__ == "__main__":
    main()