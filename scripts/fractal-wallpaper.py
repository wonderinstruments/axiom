#!/usr/bin/env python3
"""
Fractal wallpaper generator that uses a color palette.
Generates Mandelbrot or Julia set fractals with configurable parameters.
"""

import argparse
import numpy as np
from PIL import Image
import colorsys


def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple."""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def mandelbrot(c, max_iter):
    """Calculate Mandelbrot set membership."""
    z = 0
    for n in range(max_iter):
        if abs(z) > 2:
            return n
        z = z*z + c
    return max_iter


def julia(z, c, max_iter):
    """Calculate Julia set membership."""
    for n in range(max_iter):
        if abs(z) > 2:
            return n
        z = z*z + c
    return max_iter


def generate_fractal(width, height, fractal_type, max_iter, zoom, center_x, center_y, julia_c_real, julia_c_imag):
    """Generate fractal data."""
    result = np.zeros((height, width))
    
    # Calculate bounds
    aspect_ratio = width / height
    x_min = center_x - (2.0 / zoom) * aspect_ratio
    x_max = center_x + (2.0 / zoom) * aspect_ratio
    y_min = center_y - (2.0 / zoom)
    y_max = center_y + (2.0 / zoom)
    
    for py in range(height):
        for px in range(width):
            x = x_min + (x_max - x_min) * px / width
            y = y_min + (y_max - y_min) * py / height
            
            if fractal_type == "mandelbrot":
                c = complex(x, y)
                result[py, px] = mandelbrot(c, max_iter)
            else:  # julia
                z = complex(x, y)
                c = complex(julia_c_real, julia_c_imag)
                result[py, px] = julia(z, c, max_iter)
    
    return result


def colorize_fractal(fractal_data, colors, max_iter):
    """Apply color palette to fractal data."""
    height, width = fractal_data.shape
    image = Image.new('RGB', (width, height))
    pixels = image.load()
    
    # Convert hex colors to RGB
    rgb_colors = [hex_to_rgb(c) for c in colors]
    
    for py in range(height):
        for px in range(width):
            iteration = fractal_data[py, px]
            
            if iteration == max_iter:
                # Points in the set get the first color
                pixels[px, py] = rgb_colors[0]
            else:
                # Smooth color interpolation
                color_index = (iteration / max_iter) * (len(rgb_colors) - 1)
                idx1 = int(color_index)
                idx2 = min(idx1 + 1, len(rgb_colors) - 1)
                blend = color_index - idx1
                
                # Interpolate between two colors
                c1 = rgb_colors[idx1]
                c2 = rgb_colors[idx2]
                r = int(c1[0] * (1 - blend) + c2[0] * blend)
                g = int(c1[1] * (1 - blend) + c2[1] * blend)
                b = int(c1[2] * (1 - blend) + c2[2] * blend)
                
                pixels[px, py] = (r, g, b)
    
    return image


def main():
    parser = argparse.ArgumentParser(description='Generate fractal wallpaper')
    parser.add_argument('--output', required=True, help='Output image path')
    parser.add_argument('--width', type=int, default=1920, help='Image width')
    parser.add_argument('--height', type=int, default=1080, help='Image height')
    parser.add_argument('--type', choices=['mandelbrot', 'julia'], default='mandelbrot', help='Fractal type')
    parser.add_argument('--iterations', type=int, default=256, help='Maximum iterations')
    parser.add_argument('--zoom', type=float, default=1.0, help='Zoom level')
    parser.add_argument('--center-x', type=float, default=-0.5, help='Center X coordinate')
    parser.add_argument('--center-y', type=float, default=0.0, help='Center Y coordinate')
    parser.add_argument('--julia-c-real', type=float, default=-0.7, help='Julia set C real part')
    parser.add_argument('--julia-c-imag', type=float, default=0.27015, help='Julia set C imaginary part')
    parser.add_argument('--colors', nargs='+', required=True, help='Hex color palette (space-separated)')
    
    args = parser.parse_args()
    
    print(f"Generating {args.type} fractal ({args.width}x{args.height})...")
    fractal_data = generate_fractal(
        args.width, args.height, args.type, args.iterations,
        args.zoom, args.center_x, args.center_y,
        args.julia_c_real, args.julia_c_imag
    )
    
    print(f"Colorizing with {len(args.colors)} colors...")
    image = colorize_fractal(fractal_data, args.colors, args.iterations)
    
    print(f"Saving to {args.output}...")
    image.save(args.output)
    print("Done!")


if __name__ == '__main__':
    main()
