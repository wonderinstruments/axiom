"""
Theme colors from Stylix configuration.
Colors are loaded from ~/.config/axiom/colors at runtime.
"""

import json
from pathlib import Path


def _load_colors():
    """Load colors from the config file."""
    colors_file = Path.home() / ".config" / "axiom" / "colors"
    if not colors_file.exists():
        raise FileNotFoundError(
            f"Colors file not found at {colors_file}. "
            "Please rebuild your system to generate it."
        )
    return json.loads(colors_file.read_text())


# Load colors at import time
_colors = _load_colors()

# Base16 color scheme
base00 = _colors["base00"]  # Default Background
base01 = _colors["base01"]  # Lighter Background
base02 = _colors["base02"]  # Selection Background
base03 = _colors["base03"]  # Comments, Invisibles
base04 = _colors["base04"]  # Dark Foreground
base05 = _colors["base05"]  # Default Foreground
base06 = _colors["base06"]  # Light Foreground
base07 = _colors["base07"]  # Light Background
base08 = _colors["base08"]  # Red
base09 = _colors["base09"]  # Orange
base0A = _colors["base0A"]  # Yellow
base0B = _colors["base0B"]  # Green
base0C = _colors["base0C"]  # Cyan
base0D = _colors["base0D"]  # Blue
base0E = _colors["base0E"]  # Purple
base0F = _colors["base0F"]  # Brown

# Semantic color names
background = base00
foreground = base05
red = base08
orange = base09
yellow = base0A
green = base0B
cyan = base0C
blue = base0D
purple = base0E
brown = base0F

# All colors as a list
all_colors = [
    base00, base01, base02, base03,
    base04, base05, base06, base07,
    base08, base09, base0A, base0B,
    base0C, base0D, base0E, base0F,
]


def to_rgb(hex_color: str) -> tuple[int, int, int]:
    """Convert hex color to RGB tuple."""
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i : i + 2], 16) for i in (0, 2, 4))


def to_rgba(hex_color: str, alpha: float = 1.0) -> tuple[int, int, int, float]:
    """Convert hex color to RGBA tuple."""
    r, g, b = to_rgb(hex_color)
    return (r, g, b, alpha)
