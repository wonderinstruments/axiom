{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.keybindings;
in
{
  options.axiom.keybindings = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable custom i3 keybindings configuration.";
    };

    newTerminal = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+Return";
      description = "Key combination to open a new terminal window.";
    };

    applicationLauncher = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+space";
      description = "Key combination to launch the application launcher.";
    };

    windowSwitcher = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+Tab";
      description = "Key combination to open the window switcher.";
    };

    metaLauncher = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+Escape";
      description = "Key combination to open the meta-launcher (launcher menu).";
    };

    # Window focus (vim-inspired)
    focusLeft = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+h";
      description = "Focus window to the left.";
    };
    focusDown = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+j";
      description = "Focus window below.";
    };
    focusUp = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+k";
      description = "Focus window above.";
    };
    focusRight = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+l";
      description = "Focus window to the right.";
    };

    # Move windows (vim + shift)
    moveLeft = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+Shift+h";
      description = "Move window to the left.";
    };
    moveDown = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+Shift+j";
      description = "Move window down.";
    };
    moveUp = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+Shift+k";
      description = "Move window up.";
    };
    moveRight = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+Shift+l";
      description = "Move window to the right.";
    };

    # Splitting
    splitHorizontal = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+s";
      description = "Split container horizontally (new window below).";
    };
    splitVertical = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+v";
      description = "Split container vertically (new window right).";
    };

    # Window actions
    closeWindow = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+q";
      description = "Close focused window.";
    };
    toggleFullscreen = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+f";
      description = "Toggle fullscreen for focused window.";
    };

    # Workspace navigation
    workspace1 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+1";
      description = "Switch to workspace 1.";
    };
    workspace2 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+2";
      description = "Switch to workspace 2.";
    };
    workspace3 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+3";
      description = "Switch to workspace 3.";
    };
    workspace4 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+4";
      description = "Switch to workspace 4.";
    };
    workspace5 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+5";
      description = "Switch to workspace 5.";
    };
    workspace6 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+6";
      description = "Switch to workspace 6.";
    };
    workspace7 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+7";
      description = "Switch to workspace 7.";
    };
    workspace8 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+8";
      description = "Switch to workspace 8.";
    };
    workspace9 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+9";
      description = "Switch to workspace 9.";
    };
    workspace10 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+0";
      description = "Switch to workspace 10.";
    };

    # Move to workspace
    moveToWorkspace1 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+Shift+1";
      description = "Move window to workspace 1.";
    };
    moveToWorkspace2 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+Shift+2";
      description = "Move window to workspace 2.";
    };
    moveToWorkspace3 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+Shift+3";
      description = "Move window to workspace 3.";
    };
    moveToWorkspace4 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+Shift+4";
      description = "Move window to workspace 4.";
    };
    moveToWorkspace5 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+Shift+5";
      description = "Move window to workspace 5.";
    };
    moveToWorkspace6 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+Shift+6";
      description = "Move window to workspace 6.";
    };
    moveToWorkspace7 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+Shift+7";
      description = "Move window to workspace 7.";
    };
    moveToWorkspace8 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+Shift+8";
      description = "Move window to workspace 8.";
    };
    moveToWorkspace9 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+Shift+9";
      description = "Move window to workspace 9.";
    };
    moveToWorkspace10 = lib.mkOption {
      type = lib.types.str;
      default = "Mod4+Shift+0";
      description = "Move window to workspace 10.";
    };

    extraKeybindings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Additional custom keybindings as an attribute set of key -> command.";
    };
  };

  config = lib.mkIf cfg.enable {
    xsession.windowManager.i3 = {
      enable = true;
      config = {
        modifier = "Mod4";
        terminal = "kitty";

        keybindings = lib.mkOptionDefault (
          {
            # Application shortcuts
            "${cfg.newTerminal}" = "exec kitty";
            "${cfg.applicationLauncher}" = "exec rofi -show drun -config ~/.config/rofi/app-launcher.rasi";
            "${cfg.windowSwitcher}" = "exec ~/.local/bin/rofi-window-switcher";
            "${cfg.metaLauncher}" = "exec ~/.local/bin/rofi-meta-launcher";

            # Window focus (vim-inspired)
            "${cfg.focusLeft}" = "focus left";
            "${cfg.focusDown}" = "focus down";
            "${cfg.focusUp}" = "focus up";
            "${cfg.focusRight}" = "focus right";

            # Move windows (vim + shift)
            "${cfg.moveLeft}" = "move left";
            "${cfg.moveDown}" = "move down";
            "${cfg.moveUp}" = "move up";
            "${cfg.moveRight}" = "move right";

            # Splitting
            "${cfg.splitHorizontal}" = "split h";
            "${cfg.splitVertical}" = "split v";

            # Window actions
            "${cfg.closeWindow}" = "kill";
            "${cfg.toggleFullscreen}" = "fullscreen toggle";

            # Workspace navigation
            "${cfg.workspace1}" = "workspace number 1";
            "${cfg.workspace2}" = "workspace number 2";
            "${cfg.workspace3}" = "workspace number 3";
            "${cfg.workspace4}" = "workspace number 4";
            "${cfg.workspace5}" = "workspace number 5";
            "${cfg.workspace6}" = "workspace number 6";
            "${cfg.workspace7}" = "workspace number 7";
            "${cfg.workspace8}" = "workspace number 8";
            "${cfg.workspace9}" = "workspace number 9";
            "${cfg.workspace10}" = "workspace number 10";

            # Move to workspace
            "${cfg.moveToWorkspace1}" = "move container to workspace number 1";
            "${cfg.moveToWorkspace2}" = "move container to workspace number 2";
            "${cfg.moveToWorkspace3}" = "move container to workspace number 3";
            "${cfg.moveToWorkspace4}" = "move container to workspace number 4";
            "${cfg.moveToWorkspace5}" = "move container to workspace number 5";
            "${cfg.moveToWorkspace6}" = "move container to workspace number 6";
            "${cfg.moveToWorkspace7}" = "move container to workspace number 7";
            "${cfg.moveToWorkspace8}" = "move container to workspace number 8";
            "${cfg.moveToWorkspace9}" = "move container to workspace number 9";
            "${cfg.moveToWorkspace10}" = "move container to workspace number 10";
          }
          // cfg.extraKeybindings
        );
      };
    };
  };
}
