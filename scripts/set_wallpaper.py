#!/usr/bin/env python3
"""
Set the system wallpaper using axiom.
"""

import argparse
import sys
from pathlib import Path

import axiom.wallpaper


def main():
    parser = argparse.ArgumentParser(description="Set the system wallpaper")
    parser.add_argument("path", type=str, help="Path to the wallpaper image")

    args = parser.parse_args()

    # Convert to Path and validate
    wallpaper_path = Path(args.path).expanduser().resolve()

    if not wallpaper_path.exists():
        print(f"Error: File not found: {wallpaper_path}", file=sys.stderr)
        sys.exit(1)

    if not wallpaper_path.is_file():
        print(f"Error: Not a file: {wallpaper_path}", file=sys.stderr)
        sys.exit(1)

    # Check if it's an image file (basic check by extension)
    valid_extensions = {".png", ".jpg", ".jpeg", ".bmp", ".gif", ".webp"}
    if wallpaper_path.suffix.lower() not in valid_extensions:
        print(
            f"Warning: {wallpaper_path.suffix} may not be a valid image format",
            file=sys.stderr,
        )
        response = input("Continue anyway? [y/N] ")
        if response.lower() != "y":
            sys.exit(1)

    # Set the wallpaper
    try:
        axiom.wallpaper.set(wallpaper_path)
        print(f"✓ Wallpaper set to: {wallpaper_path}")
    except Exception as e:
        print(f"Error setting wallpaper: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
