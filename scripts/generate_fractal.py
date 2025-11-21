#!/usr/bin/env python3
"""
Generate a fractal image using theme colors and display it in the terminal.
"""

import argparse
import random
from datetime import datetime
from pathlib import Path

import numpy as np
from PIL import Image
from term_image.image import from_file
from tqdm import tqdm

import axiom.colors
import axiom.wallpaper


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


def sample_region(
    center_x,
    center_y,
    zoom,
    fractal_type,
    max_iter,
    julia_c_real,
    julia_c_imag,
    sample_size=25,
):
    """Sample a region and calculate interest metrics."""
    samples_in = 0
    samples_out = 0
    iteration_variance = []

    # Sample in a grid
    for i in range(sample_size):
        for j in range(sample_size):
            # Convert to complex coordinates
            x_offset = (i / sample_size - 0.5) * 2.0 / zoom
            y_offset = (j / sample_size - 0.5) * 2.0 / zoom
            x = center_x + x_offset
            y = center_y + y_offset

            if fractal_type == "mandelbrot":
                c = complex(x, y)
                iterations = mandelbrot(c, max_iter)
            else:  # julia
                z = complex(x, y)
                c = complex(julia_c_real, julia_c_imag)
                iterations = julia(z, c, max_iter)

            if iterations == max_iter:
                samples_in += 1
            else:
                samples_out += 1
                iteration_variance.append(iterations)

    total = samples_in + samples_out
    fraction_in = samples_in / total
    fraction_out = samples_out / total

    # Interest score based on multiple factors:
    # 1. Boundary presence (50/50 mix)
    boundary_score = 4 * fraction_in * fraction_out  # Peaks at 0.5/0.5

    # 2. Iteration variance (more interesting if escape times vary)
    variance_score = 0
    if len(iteration_variance) > 1:
        variance = np.var(iteration_variance)
        variance_score = min(variance / (max_iter * 0.3), 1.0)  # Normalize

    # 3. Not too empty or too full
    density_penalty = 1.0
    if fraction_in < 0.05 or fraction_in > 0.95:
        density_penalty = 0.3

    # Combine scores
    interest = (boundary_score * 0.6 + variance_score * 0.4) * density_penalty

    return interest, fraction_in, fraction_out


def find_interesting_region(fractal_type, max_iter, julia_c_real, julia_c_imag, depth=3):
    """Recursively find an interesting region with boundary detail."""

    # Start with a broad search area
    if fractal_type == "mandelbrot":
        # Search around known interesting regions of Mandelbrot
        search_regions = [
            (-0.7, 0.0, 0.5),  # Main boundary
            (-0.5, 0.5, 0.3),  # Upper spiral
            (-0.5, -0.5, 0.3),  # Lower spiral
            (-1.25, 0.0, 0.4),  # Left bulb area
            (0.25, 0.0, 0.2),  # Right side
            (-0.16, 1.04, 0.2),  # Top antenna
            (-0.75, 0.1, 0.3),  # Elephant valley
            (-0.1, 0.65, 0.25),  # Upper tendrils
        ]
        center_x, center_y, initial_zoom = random.choice(search_regions)
    else:
        # For Julia sets, search around origin
        center_x = random.uniform(-0.5, 0.5)
        center_y = random.uniform(-0.5, 0.5)
        initial_zoom = 0.8

    # Recursively zoom into interesting areas
    zoom = initial_zoom

    for level in range(depth):
        best_interest = 0
        best_x = center_x
        best_y = center_y

        # Adaptive grid size - start larger, get more precise
        grid_size = 7 if level == 0 else 5
        search_radius = 1.2 / zoom  # Slightly larger search radius

        # Track top candidates for diversity
        candidates = []

        for i in range(grid_size):
            for j in range(grid_size):
                # Create a grid of test points
                test_x = center_x + (i / (grid_size - 1) - 0.5) * search_radius
                test_y = center_y + (j / (grid_size - 1) - 0.5) * search_radius

                interest, frac_in, frac_out = sample_region(
                    test_x,
                    test_y,
                    zoom,
                    fractal_type,
                    max_iter,
                    julia_c_real,
                    julia_c_imag,
                )

                candidates.append((interest, test_x, test_y))

                if interest > best_interest:
                    best_interest = interest
                    best_x = test_x
                    best_y = test_y

        # Add slight randomness to avoid getting stuck in local maxima
        # 80% of the time use best, 20% use top 3
        if random.random() < 0.8 or level == depth - 1:
            center_x = best_x
            center_y = best_y
        else:
            # Pick from top 3 candidates
            candidates.sort(reverse=True, key=lambda x: x[0])
            top_candidates = candidates[: min(3, len(candidates))]
            _, center_x, center_y = random.choice(top_candidates)

        # Zoom in for next iteration - more aggressive at later depths
        zoom_factor = (
            random.uniform(2.5, 4.0) if level > 0 else random.uniform(2.0, 3.0)
        )
        zoom *= zoom_factor

        print(
            f"  Depth {level + 1}/{depth}: interest={best_interest:.3f}, zoom={zoom:.2f}"
        )

    return center_x, center_y, zoom


def generate_fractal(
    width,
    height,
    fractal_type,
    max_iter,
    zoom,
    center_x,
    center_y,
    julia_c_real,
    julia_c_imag,
):
    """Generate fractal data."""
    result = np.zeros((height, width))

    # Calculate bounds
    aspect_ratio = width / height
    x_min = center_x - (2.0 / zoom) * aspect_ratio
    x_max = center_x + (2.0 / zoom) * aspect_ratio
    y_min = center_y - (2.0 / zoom)
    y_max = center_y + (2.0 / zoom)

    for py in tqdm(range(height), desc="Generating fractal", unit="row"):
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
    image = Image.new("RGB", (width, height))
    pixels = image.load()

    # Convert hex colors to RGB
    rgb_colors = [hex_to_rgb(c) for c in colors]

    for py in tqdm(range(height), desc="Colorizing", unit="row"):
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
    parser = argparse.ArgumentParser(
        description="Generate fractal image using theme colors"
    )
    parser.add_argument(
        "--width", type=int, default=1920, help="Image width (default: 1920)"
    )
    parser.add_argument(
        "--height", type=int, default=1080, help="Image height (default: 1080)"
    )
    parser.add_argument(
        "--type",
        choices=["mandelbrot", "julia"],
        default="mandelbrot",
        help="Fractal type (default: mandelbrot)",
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=256,
        help="Maximum iterations (default: 256)",
    )
    parser.add_argument(
        "--search-depth",
        type=int,
        default=3,
        help="Depth of recursive search for interesting regions (default: 3)",
    )
    parser.add_argument(
        "--julia-c-real",
        type=float,
        default=-0.7,
        help="Julia set C real part (default: -0.7)",
    )
    parser.add_argument(
        "--julia-c-imag",
        type=float,
        default=0.27015,
        help="Julia set C imaginary part (default: 0.27015)",
    )
    parser.add_argument(
        "--seed", type=int, default=None, help="Random seed for reproducibility"
    )
    parser.add_argument(
        "--output",
        type=str,
        default=None,
        help="Output path (default: ~/Documents/fractal_TIMESTAMP.png)",
    )

    args = parser.parse_args()

    # Set random seed if provided
    if args.seed is not None:
        random.seed(args.seed)
        np.random.seed(args.seed)

    # Determine output path
    if args.output:
        output_path = Path(args.output)
    else:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_path = Path.home() / "Documents" / f"fractal_{timestamp}.png"

    # Ensure output directory exists
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Use axiom colors
    colors = axiom.colors.all_colors

    print(f"Searching for interesting {args.type} region...")
    center_x, center_y, zoom = find_interesting_region(
        args.type,
        args.iterations,
        args.julia_c_real,
        args.julia_c_imag,
        depth=args.search_depth,
    )
    print(f"Found region: center=({center_x:.6f}, {center_y:.6f}), zoom={zoom:.2f}\n")

    fractal_data = generate_fractal(
        args.width,
        args.height,
        args.type,
        args.iterations,
        zoom,
        center_x,
        center_y,
        args.julia_c_real,
        args.julia_c_imag,
    )

    image = colorize_fractal(fractal_data, colors, args.iterations)

    print(f"\nSaving to {output_path}...")
    image.save(output_path)
    print(f"✓ Saved to {output_path}\n")

    # Display in terminal
    print("Displaying image in terminal...\n")
    term_image = from_file(str(output_path))
    term_image.draw()

    # Ask if user wants to set as wallpaper
    print()
    response = input("Set this as your wallpaper? [y/N] ")
    if response.lower() == "y":
        try:
            axiom.wallpaper.set(output_path)
            print(f"✓ Wallpaper set!")
        except Exception as e:
            print(f"Error setting wallpaper: {e}")


if __name__ == "__main__":
    main()
