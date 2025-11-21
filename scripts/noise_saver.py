#!/usr/bin/env python3
"""
Noise pattern screensaver - animated Perlin noise visualization.
Uses axiom theme colors for a cohesive look.
"""

import time
from PIL import Image
from term_image.image import AutoImage
from noise import pnoise2, snoise2

import axiom.colors


def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple."""
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i : i + 2], 16) for i in (0, 2, 4))


def create_noise_frame(width, height, time_offset, scale=0.05, octaves=4, noise_type="perlin"):
    """Generate a noise pattern frame using Perlin or Simplex noise."""
    image = Image.new("RGB", (width, height))
    pixels = image.load()
    
    # Get theme colors
    colors = axiom.colors.all_colors
    rgb_colors = [hex_to_rgb(c) for c in colors]
    
    for y in range(height):
        for x in range(width):
            # Generate 2D noise with time as third dimension
            if noise_type == "perlin":
                noise_val = pnoise2(
                    x * scale,
                    y * scale + time_offset,
                    octaves=octaves,
                    persistence=0.5,
                    lacunarity=2.0,
                    repeatx=1024,
                    repeaty=1024
                )
            else:  # simplex
                noise_val = snoise2(
                    x * scale,
                    y * scale + time_offset,
                    octaves=octaves
                )
            
            # Normalize from [-1, 1] to [0, 1]
            normalized = (noise_val + 1) / 2
            
            # Map to color palette
            color_index = normalized * (len(rgb_colors) - 1)
            idx1 = int(color_index)
            idx2 = min(idx1 + 1, len(rgb_colors) - 1)
            blend = color_index - idx1
            
            # Interpolate colors
            c1 = rgb_colors[idx1]
            c2 = rgb_colors[idx2]
            r = int(c1[0] * (1 - blend) + c2[0] * blend)
            g = int(c1[1] * (1 - blend) + c2[1] * blend)
            b = int(c1[2] * (1 - blend) + c2[2] * blend)
            
            pixels[x, y] = (r, g, b)
    
    return image


def create_turbulence_frame(width, height, time_offset, scale=0.03):
    """Create turbulent pattern by combining multiple noise octaves."""
    image = Image.new("RGB", (width, height))
    pixels = image.load()
    
    colors = axiom.colors.all_colors
    rgb_colors = [hex_to_rgb(c) for c in colors]
    
    for y in range(height):
        for x in range(width):
            # Combine multiple noise layers
            noise1 = pnoise2(x * scale, y * scale + time_offset, octaves=4)
            noise2 = pnoise2(x * scale * 2, y * scale * 2 + time_offset * 1.5, octaves=3)
            noise3 = pnoise2(x * scale * 4, y * scale * 4 + time_offset * 2, octaves=2)
            
            # Turbulence mixing
            combined = abs(noise1) * 0.5 + abs(noise2) * 0.3 + abs(noise3) * 0.2
            normalized = min(combined, 1.0)
            
            # Map to colors
            color_index = normalized * (len(rgb_colors) - 1)
            idx1 = int(color_index)
            idx2 = min(idx1 + 1, len(rgb_colors) - 1)
            blend = color_index - idx1
            
            c1 = rgb_colors[idx1]
            c2 = rgb_colors[idx2]
            r = int(c1[0] * (1 - blend) + c2[0] * blend)
            g = int(c1[1] * (1 - blend) + c2[1] * blend)
            b = int(c1[2] * (1 - blend) + c2[2] * blend)
            
            pixels[x, y] = (r, g, b)
    
    return image


def main():
    # Configuration
    width, height = 320, 160
    
    # Pattern types
    patterns = [
        ("Perlin", "perlin", 0.05),
        ("Simplex", "simplex", 0.05),
        ("Turbulence", "turbulence", 0.03),
    ]
    
    current_idx = 0
    pattern_name, pattern_type, scale = patterns[current_idx]
    
    print(f"Starting noise pattern screensaver...")
    print(f"Pattern: {pattern_name}")
    print("Press Ctrl+C to exit")
    print()
    
    time_offset = 0.0
    frame_count = 0
    
    try:
        while True:
            # Generate frame
            if pattern_type == "turbulence":
                image = create_turbulence_frame(width, height, time_offset, scale)
            else:
                image = create_noise_frame(width, height, time_offset, scale, noise_type=pattern_type)
            
            # Display in terminal
            term_image = AutoImage(image)
            term_image.draw()
            
            # Advance animation
            time_offset += 0.5
            frame_count += 1
            
            # Switch patterns periodically
            if frame_count % 100 == 0:
                current_idx = (current_idx + 1) % len(patterns)
                old_pattern = pattern_name
                pattern_name, pattern_type, scale = patterns[current_idx]
                print(f"\nSwitching from {old_pattern} to {pattern_name}...")
                time_offset = 0.0
            
            # Frame delay
            time.sleep(0.15)
    
    except KeyboardInterrupt:
        print("\nExiting noise screensaver...")


if __name__ == "__main__":
    main()
