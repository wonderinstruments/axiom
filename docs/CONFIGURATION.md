# System Configuration

This guide explains how to customize your Axiom system by editing your configuration file.

## Overview

Your settings are stored in `~/config/axiom/config.conf`. This file controls:

- Theme colors and appearance
- Terminal font size
- Keyboard shortcuts
- Screensaver settings
- Enable/disable features

## Quick Start

### Changing Your Theme

1. Open the config file:
   ```bash
   micro ~/config/axiom/config.conf
   ```

2. Find the `theme` section and change the color scheme:
   ```hocon
   theme {
     colors = "everforest"  # Try: rose-pine-moon, moonlight, etc.
   }
   ```

3. Apply the changes:
   ```bash
   axiom-rebuild
   ```

The system will automatically rebuild with your new settings.

## Editing Your Configuration

You can use either text editor:

- **micro** - Simple, beginner-friendly
  ```bash
  micro ~/config/axiom/config.conf
  ```

- **nvim** - Advanced, powerful
  ```bash
  nvim ~/config/axiom/config.conf
  ```

### Common Settings

#### Terminal Font Size
```hocon
terminal {
  fontSize = 18  # Change to your preferred size
}
```

#### Keyboard Shortcuts
```hocon
keybindings {
  newTerminal = "Mod4+Return"          # Super+Enter
  applicationLauncher = "Mod4+space"   # Super+Space
  closeWindow = "Mod4+q"               # Super+Q
}
```

#### Screensaver
```hocon
screensaver {
  enable = true
  sleepAfterMinutes = 10
  command = "cmatrix -a -b"  # Matrix effect
}
```

#### Window Appearance
```hocon
theme {
  windows {
    gap.size = 10      # Space between windows
    shadow.size = 50   # Shadow effect size
  }
}
```

#### Fractal Wallpaper
```hocon
fractal-wallpaper {
  enable = true
  width = 1920
  height = 1080
  fractalType = "mandelbrot"  # or "julia"
  iterations = 100
}
```

## Understanding axiom-rebuild

When you run `axiom-rebuild`:

1. **Parses** your HOCON config file
2. **Validates** the settings
3. **Generates** Nix configuration
4. **Shows** what changed (diff view)
5. **Rebuilds** the system
6. **Applies** the changes

The process is automatic and takes 1-3 minutes.

### Options

- `axiom-rebuild` - Full rebuild
- `axiom-rebuild --no-rebuild` - Generate config without rebuilding
- `axiom-rebuild --init` - Create config file from template
- `axiom-rebuild --reset` - Reset config to defaults

## Available Theme Colors

Choose from these color schemes in the `theme.colors` setting:

- `rose-pine-moon` - Soft purple tones
- `everforest` - Warm forest greens
- `moonlight` - Cool blue night theme
- `spaceduck` - Retro space theme
- `woodland` - Natural earth tones
- `sandcastle` - Warm desert colors
- `selenized-dark` - High contrast
- `tokyo-night-storm` - Dark blue-gray
- `zenbones` - Minimal aesthetic
- `eris` - Purple and pink (default)
- `blueforest` - Cool forest blues
- `aztec` - Vibrant southwestern
- `zenburn` - Low contrast, easy on eyes

## Troubleshooting

### Config file syntax error

If `axiom-rebuild` reports a syntax error, check:
- Missing quotes around strings with spaces
- Unclosed braces `{}`
- Typos in option names

You can reset to defaults:
```bash
axiom-rebuild --reset
```

### Changes not applying

Make sure you ran `axiom-rebuild` after editing. The system won't change until you rebuild.

## Learning More

- Run `navi` to see command examples
- Read other docs in `~/docs/` (open with `glow ~/docs`)
- Check your current config: `cat ~/config/axiom/config.conf`

## Tips

- **Preview changes**: Use `axiom-rebuild --no-rebuild` to see what would change without applying
- **Experiment safely**: You can always reset with `axiom-rebuild --reset`
- **Small changes**: Test one setting at a time to see what each does
- **Keep backups**: Your old config is backed up automatically when you reset
