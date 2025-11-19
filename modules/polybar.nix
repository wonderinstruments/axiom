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
        transparent = "#00000000";
      };

      # Main bar configuration
      "bar/main" = {
        monitor = "\${env:MONITOR:}";
        width = "100%";
        height = "32pt";
        radius = 0;
        bottom = true;
        override-redirect = true;

        background = "\${colors.transparent}";
        foreground = "\${colors.foreground}";

        line.size = "0pt";

        border.size = "0pt";
        border.color = "\${colors.transparent}";

        padding.left = 0;
        padding.right = 0;
        padding.top = 0;
        padding.bottom = 0;

        module.margin = 0;

        separator = "";

        font = [
          "Atkinson Hyperlegible:style=Bold:size=14;2"
          "Font Awesome 6 Free Solid:size=16;2"
          "Font Awesome 6 Brands:size=11;2"
        ];

        modules.center = "ws-left i3workspaces ws-right";
        modules.right = "right-start systray date time right-end";

        cursor.click = "pointer";
        cursor.scroll = "ns-resize";

        enable-ipc = true;

        tray-position = "none";
      };

      # Workspace pill left cap
      "module/ws-left" = {
        type = "custom/text";
        content = "";
        content-background = "\${colors.transparent}";
        content-foreground = "\${colors.background}";
      };

      # Workspace pill right cap
      "module/ws-right" = {
        type = "custom/text";
        content = "";
        content-background = "\${colors.transparent}";
        content-foreground = "\${colors.background}";
      };

      # Right pill start
      "module/right-start" = {
        type = "custom/text";
        content = "";
        content-background = "\${colors.transparent}";
        content-foreground = "\${colors.background}";
      };

      # Right pill end
      "module/right-end" = {
        type = "custom/text";
        content = "";
        content-background = "\${colors.transparent}";
        content-foreground = "\${colors.background}";
      };

      # System tray
      "module/systray" = {
        type = "internal/tray";
        tray-spacing = "8pt";
        tray-background = "\${colors.background}";
        tray-padding = 2;
      };

      # i3 workspaces module with circles
      "module/i3workspaces" = {
        type = "internal/i3";

        pin-workspaces = true;
        show-urgent = true;
        strip-wsnumbers = false;
        index-sort = true;

        format = "<label-state>";
        format-background = "\${colors.background}";

        # Use circle icons - make square with equal padding
        label-focused = "   %index%   ";
        label-focused-foreground = "\${colors.primary}";
        label-focused-background = "\${colors.background}";
        label-focused-padding = 0;

        label-unfocused = "   %index%   ";
        label-unfocused-foreground = "\${colors.disabled}";
        label-unfocused-background = "\${colors.background}";
        label-unfocused-padding = 0;

        label-visible = "   %index%   ";
        label-visible-foreground = "\${colors.secondary}";
        label-visible-background = "\${colors.background}";
        label-visible-padding = 0;

        label-urgent = "   %index%   ";
        label-urgent-foreground = "\${colors.alert}";
        label-urgent-background = "\${colors.background}";
        label-urgent-padding = 0;
      };

      # Date module
      "module/date" = {
        type = "internal/date";
        interval = 60;

        date = "%a %b %d";

        format = "<label>";
        format-background = "\${colors.background}";
        format-padding = 0;
        format-margin = 0;
        label = " %date%";
      };

      # Time module
      "module/time" = {
        type = "internal/date";
        interval = 1;

        time = "%I:%M %p";

        format = "<label>";
        format-background = "\${colors.background}";
        format-padding = 0;
        format-margin = 0;
        label = " %time%";
      };

      # Global settings
      "settings" = {
        screenchange.reload = true;
        pseudo.transparency = true;
      };
    };
  };
}
