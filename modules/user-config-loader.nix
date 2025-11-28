# User Configuration Loader
#
# This module reads user configuration from ~/.config/axiom/config.toml
# and maps the values to the appropriate axiom.* options.
#
# Users can edit the TOML file directly without touching Nix code.
# On rebuild, if the config file doesn't exist, it's copied from the template.

{ lib, config, pkgs, ... }:

let
  # Path to user's config file
  userConfigPath = "${config.home.homeDirectory}/.config/axiom/config.toml";
  
  # Path to the template (in the nix-config repo)
  templatePath = ../templates/user-config.toml;
  
  # Read and parse the TOML file if it exists, otherwise use empty attrset
  userConfig = 
    if builtins.pathExists userConfigPath
    then builtins.fromTOML (builtins.readFile userConfigPath)
    else {};
  
  # Helper function to safely get nested values with defaults
  get = path: default: lib.attrByPath path default userConfig;
  
  # Helper for boolean values (TOML booleans are native)
  getBool = path: default: let val = get path default; in val;
  
  # Helper for integer values
  getInt = path: default: let val = get path default; in val;
  
  # Helper for string values
  getStr = path: default: let val = get path default; in val;
  
  # Helper for float values
  getFloat = path: default: let val = get path default; in val;

in
{
  config = {
    # =========================================================================
    # Theme settings
    # =========================================================================
    axiom.theme.colors = getStr ["theme" "colors"] "eris";
    axiom.theme.windows.gap.size = getInt ["theme" "windows" "gap" "size"] 0;
    axiom.theme.windows.shadow.size = getInt ["theme" "windows" "shadow" "size"] 1;
    
    # =========================================================================
    # Terminal settings
    # =========================================================================
    axiom.terminal.fontSize = getInt ["terminal" "fontSize"] 12;
    
    # =========================================================================
    # Neovim settings
    # =========================================================================
    axiom.neovim.configureByConfigFile = getBool ["neovim" "configureByConfigFile"] false;
    axiom.neovim.resetConfigFileOnNextSwitch = getBool ["neovim" "resetConfigFileOnNextSwitch"] false;
    
    # =========================================================================
    # Screensaver settings
    # =========================================================================
    axiom.screensaver.enable = getBool ["screensaver" "enable"] true;
    axiom.screensaver.sleepAfterMinutes = getInt ["screensaver" "sleepAfterMinutes"] 15;
    axiom.screensaver.command = getStr ["screensaver" "command"] "${pkgs.cmatrix}/bin/cmatrix -a -b";
    
    # =========================================================================
    # Fractal wallpaper settings
    # =========================================================================
    axiom.fractal-wallpaper.enable = getBool ["fractal-wallpaper" "enable"] true;
    axiom.fractal-wallpaper.width = getInt ["fractal-wallpaper" "width"] 1920;
    axiom.fractal-wallpaper.height = getInt ["fractal-wallpaper" "height"] 1080;
    axiom.fractal-wallpaper.fractalType = getStr ["fractal-wallpaper" "fractalType"] "mandelbrot";
    axiom.fractal-wallpaper.iterations = getInt ["fractal-wallpaper" "iterations"] 256;
    axiom.fractal-wallpaper.searchDepth = getInt ["fractal-wallpaper" "searchDepth"] 3;
    axiom.fractal-wallpaper.regenerateOnRebuild = getBool ["fractal-wallpaper" "regenerateOnRebuild"] true;
    axiom.fractal-wallpaper.juliaCReal = getFloat ["fractal-wallpaper" "juliaCReal"] (-0.7);
    axiom.fractal-wallpaper.juliaCImag = getFloat ["fractal-wallpaper" "juliaCImag"] 0.27015;
    
    # =========================================================================
    # Sound settings
    # =========================================================================
    axiom.sounds.enable = getBool ["sounds" "enable"] true;
    
    # =========================================================================
    # Clipboard monitor settings
    # =========================================================================
    axiom.clipboardMonitor.enable = getBool ["clipboardMonitor" "enable"] true;
    
    # =========================================================================
    # Documentation settings
    # =========================================================================
    axiom.docs.enable = getBool ["docs" "enable"] true;
    
    # =========================================================================
    # File commands settings
    # =========================================================================
    axiom.fileCommands.enable = getBool ["fileCommands" "enable"] true;
    
    # =========================================================================
    # Musopen settings
    # =========================================================================
    axiom.musopen.enable = getBool ["musopen" "enable"] true;
    
    # =========================================================================
    # GitType settings
    # =========================================================================
    axiom.gittype.enable = getBool ["gittype" "enable"] true;
    
    # =========================================================================
    # Keybindings settings
    # =========================================================================
    axiom.keybindings = {
      enable = true;
      
      # Application shortcuts
      newTerminal = getStr ["keybindings" "newTerminal"] "Mod4+Return";
      tuiLauncher = getStr ["keybindings" "tuiLauncher"] "Mod4+Shift+Return";
      applicationLauncher = getStr ["keybindings" "applicationLauncher"] "Mod4+space";
      glowLauncher = getStr ["keybindings" "glowLauncher"] "Mod4+Escape";
      windowSwitcher = getStr ["keybindings" "windowSwitcher"] "Mod4+Tab";
      
      # Window focus
      focusLeft = getStr ["keybindings" "focusLeft"] "Mod4+h";
      focusDown = getStr ["keybindings" "focusDown"] "Mod4+j";
      focusUp = getStr ["keybindings" "focusUp"] "Mod4+k";
      focusRight = getStr ["keybindings" "focusRight"] "Mod4+l";
      
      # Move windows
      moveLeft = getStr ["keybindings" "moveLeft"] "Mod4+Shift+h";
      moveDown = getStr ["keybindings" "moveDown"] "Mod4+Shift+j";
      moveUp = getStr ["keybindings" "moveUp"] "Mod4+Shift+k";
      moveRight = getStr ["keybindings" "moveRight"] "Mod4+Shift+l";
      
      # Splitting
      splitHorizontal = getStr ["keybindings" "splitHorizontal"] "Mod4+s";
      splitVertical = getStr ["keybindings" "splitVertical"] "Mod4+v";
      
      # Window actions
      closeWindow = getStr ["keybindings" "closeWindow"] "Mod4+q";
      toggleFullscreen = getStr ["keybindings" "toggleFullscreen"] "Mod4+f";
      
      # Workspace navigation
      workspace1 = getStr ["keybindings" "workspace1"] "Mod4+1";
      workspace2 = getStr ["keybindings" "workspace2"] "Mod4+2";
      workspace3 = getStr ["keybindings" "workspace3"] "Mod4+3";
      workspace4 = getStr ["keybindings" "workspace4"] "Mod4+4";
      workspace5 = getStr ["keybindings" "workspace5"] "Mod4+5";
      workspace6 = getStr ["keybindings" "workspace6"] "Mod4+6";
      workspace7 = getStr ["keybindings" "workspace7"] "Mod4+7";
      workspace8 = getStr ["keybindings" "workspace8"] "Mod4+8";
      workspace9 = getStr ["keybindings" "workspace9"] "Mod4+9";
      workspace10 = getStr ["keybindings" "workspace10"] "Mod4+0";
      
      # Move to workspace
      moveToWorkspace1 = getStr ["keybindings" "moveToWorkspace1"] "Mod4+Shift+1";
      moveToWorkspace2 = getStr ["keybindings" "moveToWorkspace2"] "Mod4+Shift+2";
      moveToWorkspace3 = getStr ["keybindings" "moveToWorkspace3"] "Mod4+Shift+3";
      moveToWorkspace4 = getStr ["keybindings" "moveToWorkspace4"] "Mod4+Shift+4";
      moveToWorkspace5 = getStr ["keybindings" "moveToWorkspace5"] "Mod4+Shift+5";
      moveToWorkspace6 = getStr ["keybindings" "moveToWorkspace6"] "Mod4+Shift+6";
      moveToWorkspace7 = getStr ["keybindings" "moveToWorkspace7"] "Mod4+Shift+7";
      moveToWorkspace8 = getStr ["keybindings" "moveToWorkspace8"] "Mod4+Shift+8";
      moveToWorkspace9 = getStr ["keybindings" "moveToWorkspace9"] "Mod4+Shift+9";
      moveToWorkspace10 = getStr ["keybindings" "moveToWorkspace10"] "Mod4+Shift+0";
    };
    
    # =========================================================================
    # Config file initialization
    # Copy template to user's config directory if it doesn't exist
    # =========================================================================
    home.activation.initAxiomUserConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      configDir="${config.home.homeDirectory}/.config/axiom"
      configFile="$configDir/config.toml"
      
      if [ ! -f "$configFile" ]; then
        run mkdir -p "$configDir"
        run cp "${templatePath}" "$configFile"
        run chmod 644 "$configFile"
        echo "Initialized Axiom user config at $configFile"
      fi
    '';
  };
}
