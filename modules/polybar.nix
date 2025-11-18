{ config, pkgs, ... }:
{
  services.polybar = {
    enable = true;
    package = pkgs.polybar.override {
      i3Support = true;
      pulseSupport = true;
    };

    script = ''
      # Kill any existing polybar instances
      ${pkgs.killall}/bin/killall -q polybar || true

      # Wait for polybar to shut down
      while ${pkgs.procps}/bin/pgrep -x polybar >/dev/null; do sleep 0.1; done

      # Launch polybar on all monitors
      for m in $(${pkgs.xorg.xrandr}/bin/xrandr --query | ${pkgs.gnugrep}/bin/grep " connected" | ${pkgs.coreutils}/bin/cut -d" " -f1); do
        echo "Launching polybar on monitor: $m" >&2
        MONITOR=$m polybar --reload main &
      done
    '';

    settings = {
      # Color definitions from Stylix
      "colors" = {
        background = "#${config.lib.stylix.colors.base00}";
        foreground = "#${config.lib.stylix.colors.base05}";
        primary = "#${config.lib.stylix.colors.base0D}";
        secondary = "#${config.lib.stylix.colors.base0C}";
        alert = "#${config.lib.stylix.colors.base08}";
        disabled = "#${config.lib.stylix.colors.base03}";
        accent = "#${config.lib.stylix.colors.base0A}";
      };

      # Main bar configuration
      "bar/main" = {
        monitor = "\${env:MONITOR:}";
        width = "100%";
        height = "32pt";
        radius = 0;
        bottom = true;

        background = "\${colors.background}";
        foreground = "\${colors.foreground}";

        line.size = "3pt";

        border.size = "4pt";
        border.color = "#00000000";

        padding.left = 1;
        padding.right = 2;

        module.margin = 1;

        separator = "|";

        font = [
          "Atkinson Hyperlegible:style=Bold:size=11;2"
          "Font Awesome 6 Free Solid:size=11;2"
          "Font Awesome 6 Brands:size=11;2"
        ];

        modules.left = "i3workspaces";
        modules.right = "date";

        cursor.click = "pointer";
        cursor.scroll = "ns-resize";

        enable-ipc = true;

        tray-position = "right";
        tray-padding = 2;
      };

      # i3 workspaces module
      "module/i3workspaces" = {
        type = "internal/i3";

        pin.workspaces = true;
        show.urgent = true;
        strip.wsnumbers = false;
        index.sort = true;

        # Workspace number label format
        label = {
          focused = {
            text = "%index%";
            background = "\${colors.primary}";
            foreground = "\${colors.background}";
            padding = 2;
          };
          unfocused = {
            text = "%index%";
            background = "\${colors.background}";
            foreground = "\${colors.foreground}";
            padding = 2;
          };
          visible = {
            text = "%index%";
            background = "\${colors.disabled}";
            foreground = "\${colors.foreground}";
            padding = 2;
          };
          urgent = {
            text = "%index%";
            background = "\${colors.alert}";
            foreground = "\${colors.background}";
            padding = 2;
          };
        };
      };

      # Date/Time module
      "module/date" = {
        type = "internal/date";
        interval = 1;

        date = "%a %b %d";
        time = "%I:%M %p";

        label = {
          text = " %date%  %time%";
          foreground = "\${colors.foreground}";
        };
      };

      # Global settings
      "settings" = {
        screenchange.reload = true;
        pseudo.transparency = false;
      };
    };
  };
}
