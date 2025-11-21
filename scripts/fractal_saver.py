#!/usr/bin/env python3
"""
Fractal zoom screensaver - continuously generates and displays fractals.
Suitable for use as a terminal screensaver.
"""

import random
import time
from pathlib import Path

import numpy as np
from PIL import Image
from term_image.image import AutoImage

import axiom.colors


def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple."""
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i : i + 2], 16) for i in (0, 2, 4))


def mandelbrot(c, max_iter):
    """Calculate Mandelbrot set membership."""
    z = 0
    for n in range(max_iter):
        if abs(z) > 2:
            return n
        z = z * z + c
    return max_iter


def julia(z, c, max_iter):
    """Calculate Julia set membership."""
    for n in range(max_iter):
        if abs(z) > 2:
            return n
        z = z * z + c
    return max_iter


def generate_fractal(
    width, height, fractal_type, max_iter, zoom, center_x, center_y, julia_c
):
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
                result[py, px] = julia(z, julia_c, max_iter)

    return result


def colorize_fractal(fractal_data, colors, max_iter):
    """Apply color palette to fractal data."""
    height, width = fractal_data.shape
    image = Image.new("RGB", (width, height))
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


def pick_interesting_location(fractal_type):
    """Pick a random interesting location in the fractal."""
    if fractal_type == "mandelbrot":
        locations = [
            (-0.7, 0.0),  # Main boundary
            (-0.5, 0.5),  # Upper spiral
            (-0.5, -0.5),  # Lower spiral
            (-1.25, 0.0),  # Left bulb
            (-0.16, 1.04),  # Top antenna
            (-0.75, 0.1),  # Elephant valley
        ]
        return random.choice(locations)
    else:  # julia
        return (random.uniform(-0.5, 0.5), random.uniform(-0.5, 0.5))


def main():
    # Terminal size (smaller for faster rendering)
    width, height = 160, 80
    max_iter = 128
    colors = axiom.colors.all_colors

    # Randomly choose fractal type
    fractal_type = random.choice(["mandelbrot", "julia"])
    
    # For Julia sets, pick an interesting constant
    if fractal_type == "julia":
        julia_constants = [
            complex(-0.7, 0.27015),
            complex(-0.835, -0.2321),
            complex(-0.8, 0.156),
            complex(0.285, 0.01),
        ]
        julia_c = random.choice(julia_constants)
    else:
        julia_c = complex(0, 0)

    # Pick starting location and zoom
    center_x, center_y = pick_interesting_location(fractal_type)
    zoom = 0.5

    print(f"Starting {fractal_type} zoom animation...")
    print("Press Ctrl+C to exit")
    print()

    try:
        frame_count = 0
        while True:
            # Generate and display fractal
            fractal_data = generate_fractal(
                width, height, fractal_type, max_iter, zoom, center_x, center_y, julia_c
            )
            image = colorize_fractal(fractal_data, colors, max_iter)

            # Display in terminal
            term_image = AutoImage(image)
            term_image.draw()

            # Zoom in gradually
            zoom *= 1.15
            frame_count += 1

            # Add small random drift to center point
            center_x += random.uniform(-0.001 / zoom, 0.001 / zoom)
            center_y += random.uniform(-0.001 / zoom, 0.001 / zoom)

            # Reset after zooming too far
            if zoom > 1e10 or frame_count > 100:
                center_x, center_y = pick_interesting_location(fractal_type)
                zoom = 0.5
                frame_count = 0
                # Occasionally switch fractal type
                if random.random() < 0.3:
                    fractal_type = random.choice(["mandelbrot", "julia"])
                    if fractal_type == "julia":
                        julia_c = random.choice(julia_constants)

            # Brief pause between frames
            time.sleep(0.5)

    except KeyboardInterrupt:
        print("\nExiting fractal screensaver...")


if __name__ == "__main__":
    main()
