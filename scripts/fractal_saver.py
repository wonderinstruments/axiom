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


def sample_region(
    center_x, center_y, zoom, fractal_type, max_iter, julia_c, sample_size=15
):
    """Sample a region to find interesting areas with detail."""
    samples_in = 0
    samples_out = 0
    iteration_variance = []

    for i in range(sample_size):
        for j in range(sample_size):
            x_offset = (i / sample_size - 0.5) * 2.0 / zoom
            y_offset = (j / sample_size - 0.5) * 2.0 / zoom
            x = center_x + x_offset
            y = center_y + y_offset

            if fractal_type == "mandelbrot":
                c = complex(x, y)
                iterations = mandelbrot(c, max_iter)
            else:
                z = complex(x, y)
                iterations = julia(z, julia_c, max_iter)

            if iterations == max_iter:
                samples_in += 1
            else:
                samples_out += 1
                iteration_variance.append(iterations)

    total = samples_in + samples_out
    fraction_in = samples_in / total
    fraction_out = samples_out / total

    # Interest score: prefer boundary areas with variance
    boundary_score = 4 * fraction_in * fraction_out
    variance_score = 0
    if len(iteration_variance) > 1:
        variance = np.var(iteration_variance)
        variance_score = min(variance / (max_iter * 0.3), 1.0)

    interest = boundary_score * 0.6 + variance_score * 0.4
    return interest


def find_zoom_target(center_x, center_y, zoom, fractal_type, max_iter, julia_c):
    """Find an interesting nearby point to zoom toward."""
    best_interest = 0
    best_x = center_x
    best_y = center_y

    # Sample a 5x5 grid around current center
    search_radius = 0.8 / zoom
    for i in range(5):
        for j in range(5):
            test_x = center_x + (i / 4 - 0.5) * search_radius
            test_y = center_y + (j / 4 - 0.5) * search_radius

            interest = sample_region(
                test_x, test_y, zoom * 1.3, fractal_type, max_iter, julia_c
            )

            if interest > best_interest:
                best_interest = interest
                best_x = test_x
                best_y = test_y

    return best_x, best_y


def main():
    # Higher resolution for better quality
    width, height = 320, 160
    max_iter = 256
    colors = axiom.colors.all_colors

    # Julia constants
    julia_constants = [
        complex(-0.7, 0.27015),
        complex(-0.835, -0.2321),
        complex(-0.8, 0.156),
        complex(0.285, 0.01),
    ]

    # Randomly choose fractal type
    fractal_type = random.choice(["mandelbrot", "julia"])
    julia_c = random.choice(julia_constants) if fractal_type == "julia" else complex(0, 0)

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

            # Find interesting nearby point to zoom toward
            if frame_count % 3 == 0:  # Update target every 3 frames
                target_x, target_y = find_zoom_target(
                    center_x, center_y, zoom, fractal_type, max_iter, julia_c
                )
            
            # Gradually move toward target
            center_x = center_x * 0.7 + target_x * 0.3
            center_y = center_y * 0.7 + target_y * 0.3

            # Zoom in gradually
            zoom *= 1.2
            frame_count += 1

            # Reset after zooming too far or too long
            if zoom > 1e12 or frame_count > 80:
                center_x, center_y = pick_interesting_location(fractal_type)
                zoom = 0.5
                frame_count = 0
                # Occasionally switch fractal type
                if random.random() < 0.3:
                    fractal_type = random.choice(["mandelbrot", "julia"])
                    julia_c = random.choice(julia_constants) if fractal_type == "julia" else complex(0, 0)
                print(f"\nSwitching to {fractal_type}...")

            # Brief pause between frames
            time.sleep(0.3)

    except KeyboardInterrupt:
        print("\nExiting fractal screensaver...")


if __name__ == "__main__":
    main()
