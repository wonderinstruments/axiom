"""
Wallpaper management for the axiom system.
"""

import os
import subprocess
from pathlib import Path


def set(path: Path) -> None:
    """
    Set the wallpaper to the specified image file.
    
    This writes the wallpaper path to ~/.config/axiom/wallpaper
    and immediately applies it using feh.
    
    Args:
        path: Path to the image file to use as wallpaper
        
    Raises:
        FileNotFoundError: If the wallpaper image doesn't exist
        subprocess.CalledProcessError: If feh fails to set the wallpaper
    """
    if not path.exists():
        raise FileNotFoundError(f"Wallpaper file not found: {path}")
    
    # Ensure config directory exists
    config_dir = Path.home() / ".config" / "axiom"
    config_dir.mkdir(parents=True, exist_ok=True)
    
    # Write wallpaper path to config file
    wallpaper_config = config_dir / "wallpaper"
    wallpaper_config.write_text(str(path.resolve()))
    
    # Set wallpaper using feh
    subprocess.run(
        ["feh", "--bg-scale", str(path)],
        check=True,
        capture_output=True,
    )


def get() -> Path | None:
    """
    Get the currently configured wallpaper path.
    
    Returns:
        Path to the current wallpaper, or None if not set
    """
    wallpaper_config = Path.home() / ".config" / "axiom" / "wallpaper"
    
    if not wallpaper_config.exists():
        return None
    
    path_str = wallpaper_config.read_text().strip()
    return Path(path_str) if path_str else None
