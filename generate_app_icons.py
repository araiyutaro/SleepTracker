#!/usr/bin/env python3
"""
Generate cute app icons for sleep tracking app
"""

from PIL import Image, ImageDraw
import os
import math

def create_app_icon(size):
    """Create a cute sleep tracking app icon at the specified size"""
    # Create a new image with RGBA mode for transparency
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Create gradient background
    for y in range(size):
        # Interpolate between #7B68EE and #9370DB
        ratio = y / size
        r = int(123 + (147 - 123) * ratio)
        g = int(104 + (112 - 104) * ratio)
        b = int(238 + (219 - 238) * ratio)
        draw.rectangle([(0, y), (size, y + 1)], fill=(r, g, b, 255))
    
    # Calculate scaling factor based on icon size
    scale = size / 1024.0
    
    # Draw fluffy clouds at the bottom
    cloud_color = (255, 255, 255, 180)
    cloud_y = size * 0.85
    
    # Draw multiple cloud circles for fluffy effect
    cloud_positions = [
        (size * 0.15, cloud_y, size * 0.12),
        (size * 0.25, cloud_y - size * 0.05, size * 0.1),
        (size * 0.35, cloud_y, size * 0.13),
        (size * 0.5, cloud_y - size * 0.03, size * 0.11),
        (size * 0.65, cloud_y, size * 0.12),
        (size * 0.75, cloud_y - size * 0.04, size * 0.1),
        (size * 0.85, cloud_y, size * 0.11),
    ]
    
    for x, y, radius in cloud_positions:
        draw.ellipse([x - radius, y - radius, x + radius, y + radius], 
                     fill=cloud_color)
    
    # Draw sleeping moon character
    moon_center_x = size * 0.5
    moon_center_y = size * 0.45
    moon_radius = size * 0.25
    
    # Moon body (crescent shape)
    # Draw full circle first
    moon_color = (255, 248, 220, 255)  # Light yellow/cream color
    draw.ellipse([moon_center_x - moon_radius, moon_center_y - moon_radius,
                  moon_center_x + moon_radius, moon_center_y + moon_radius],
                 fill=moon_color)
    
    # Create crescent by drawing overlapping circle with background color
    crescent_offset = moon_radius * 0.5
    gradient_color = (147, 112, 219, 255)  # Use the bottom gradient color
    draw.ellipse([moon_center_x - moon_radius + crescent_offset, 
                  moon_center_y - moon_radius,
                  moon_center_x + moon_radius + crescent_offset, 
                  moon_center_y + moon_radius],
                 fill=gradient_color)
    
    # Draw closed eyes (curved lines)
    eye_color = (100, 80, 60, 255)
    eye_width = int(3 * scale) if size > 40 else 2
    
    # Left eye
    left_eye_x = moon_center_x - moon_radius * 0.3
    left_eye_y = moon_center_y - moon_radius * 0.1
    eye_length = moon_radius * 0.3
    
    # Draw curved line for left eye
    points = []
    for i in range(20):
        t = i / 19.0
        x = left_eye_x - eye_length/2 + eye_length * t
        y = left_eye_y + math.sin(t * math.pi) * moon_radius * 0.08
        points.append((x, y))
    
    for i in range(len(points) - 1):
        draw.line([points[i], points[i + 1]], fill=eye_color, width=eye_width)
    
    # Right eye
    right_eye_x = moon_center_x + moon_radius * 0.1
    right_eye_y = moon_center_y - moon_radius * 0.1
    
    points = []
    for i in range(20):
        t = i / 19.0
        x = right_eye_x - eye_length/2 + eye_length * t
        y = right_eye_y + math.sin(t * math.pi) * moon_radius * 0.08
        points.append((x, y))
    
    for i in range(len(points) - 1):
        draw.line([points[i], points[i + 1]], fill=eye_color, width=eye_width)
    
    # Draw smile
    smile_y = moon_center_y + moon_radius * 0.2
    smile_width = moon_radius * 0.4
    
    points = []
    for i in range(30):
        t = i / 29.0
        x = moon_center_x - smile_width/2 + smile_width * t
        y = smile_y - math.sin(t * math.pi) * moon_radius * 0.1
        points.append((x, y))
    
    for i in range(len(points) - 1):
        draw.line([points[i], points[i + 1]], fill=eye_color, width=eye_width)
    
    # Draw stars
    star_color = (255, 255, 224, 255)  # Light yellow
    stars = [
        (size * 0.15, size * 0.2, size * 0.03),
        (size * 0.8, size * 0.15, size * 0.025),
        (size * 0.85, size * 0.35, size * 0.02),
        (size * 0.2, size * 0.6, size * 0.025),
        (size * 0.75, size * 0.65, size * 0.03),
    ]
    
    for star_x, star_y, star_size in stars:
        # Draw 4-pointed star
        points = []
        for i in range(8):
            angle = i * math.pi / 4
            if i % 2 == 0:
                r = star_size
            else:
                r = star_size * 0.4
            x = star_x + r * math.cos(angle)
            y = star_y + r * math.sin(angle)
            points.append((x, y))
        draw.polygon(points, fill=star_color)
    
    # Draw "Zzz" text (using simple lines for reliability)
    zzz_color = (255, 255, 255, 200)
    z_positions = [
        (size * 0.7, size * 0.25, size * 0.08),
        (size * 0.78, size * 0.2, size * 0.06),
        (size * 0.84, size * 0.16, size * 0.04),
    ]
    
    for x, y, z_size in z_positions:
        z_width = int(max(2, z_size * 0.1))
        
        # Draw "Z" shape with lines
        # Top horizontal line
        draw.line([(x - z_size/2, y - z_size/2), (x + z_size/2, y - z_size/2)], 
                  fill=zzz_color, width=z_width)
        
        # Diagonal line
        draw.line([(x + z_size/2, y - z_size/2), (x - z_size/2, y + z_size/2)], 
                  fill=zzz_color, width=z_width)
        
        # Bottom horizontal line
        draw.line([(x - z_size/2, y + z_size/2), (x + z_size/2, y + z_size/2)], 
                  fill=zzz_color, width=z_width)
    
    return img

def main():
    # iOS icon sizes and paths
    ios_sizes = [
        (1024, "Icon-App-1024x1024@1x.png"),
        (180, "Icon-App-60x60@3x.png"),
        (120, "Icon-App-60x60@2x.png"),
        (120, "Icon-App-40x40@3x.png"),
        (76, "Icon-App-76x76@1x.png"),
        (152, "Icon-App-76x76@2x.png"),
        (167, "Icon-App-83.5x83.5@2x.png"),
        (80, "Icon-App-40x40@2x.png"),
        (60, "Icon-App-60x60@1x.png"),
        (40, "Icon-App-40x40@1x.png"),
        (29, "Icon-App-29x29@1x.png"),
        (58, "Icon-App-29x29@2x.png"),
        (87, "Icon-App-29x29@3x.png"),
        (20, "Icon-App-20x20@1x.png"),
        (40, "Icon-App-20x20@2x.png"),
        (60, "Icon-App-20x20@3x.png"),
    ]
    
    # Android icon sizes and density folders
    android_sizes = [
        (192, "xxxhdpi"),
        (144, "xxhdpi"),
        (96, "xhdpi"),
        (72, "hdpi"),
        (48, "mdpi"),
    ]
    
    # Create iOS icons
    ios_path = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(ios_path, exist_ok=True)
    
    print("Generating iOS icons...")
    for size, filename in ios_sizes:
        icon = create_app_icon(size)
        icon.save(os.path.join(ios_path, filename), "PNG")
        print(f"  Created {filename} ({size}x{size})")
    
    # Create Android icons
    print("\nGenerating Android icons...")
    for size, density in android_sizes:
        android_path = f"android/app/src/main/res/mipmap-{density}"
        os.makedirs(android_path, exist_ok=True)
        
        icon = create_app_icon(size)
        icon.save(os.path.join(android_path, "ic_launcher.png"), "PNG")
        print(f"  Created ic_launcher.png for {density} ({size}x{size})")
    
    print("\nAll icons generated successfully!")

if __name__ == "__main__":
    main()