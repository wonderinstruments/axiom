# Axiom

System configuration library for nix-config.

## Features

- **Colors**: Access theme colors from Stylix configuration via `axiom.colors`
- **Wallpaper**: Set wallpaper programmatically via `axiom.wallpaper.set()`

## Usage

```python
from pathlib import Path
import axiom

# Access theme colors
print(axiom.colors.background)
print(axiom.colors.foreground)
print(axiom.colors.red)

# Set wallpaper
axiom.wallpaper.set(Path("/path/to/image.png"))

# Get current wallpaper
current = axiom.wallpaper.get()
```
