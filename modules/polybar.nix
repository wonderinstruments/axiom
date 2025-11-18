{ config, pkgs, ... }:
{
  services.polybar = {
    enable = true;
    package = pkgs.polybar.override {
      i3Support = true;
      pulseSupport = true;
    };
    
    script = "polybar main &";
    
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
        separator.foreground = "\${colors.disabled}";
        
        font = [
          "Atkinson Hyperlegible:style=Bold:size=11;2"
          "Font Awesome 6 Free Solid:size=11;2"
          "Font Awesome 6 Brands:size=11;2"
        ];
        
        modules.left = "rofi i3workspaces xwindow";
        modules.right = "pulseaudio network date";
        
        cursor.click = "pointer";
        cursor.scroll = "ns-resize";
        
        enable-ipc = true;
        
        tray.position = "right";
        tray.padding = 2;
      };

      # Rofi launcher module
      "module/rofi" = {
        type = "custom/text";
        content = "";
        content.foreground = "\${colors.primary}";
        click.left = "rofi -show drun";
      };

      # i3 workspaces module
      "module/i3workspaces" = {
        type = "internal/i3";
        
        pin.workspaces = false;
        show.urgent = true;
        strip.wsnumbers = false;
        index.sort = true;
        
        # Workspace number label format
        label.focused = "%index%";
        label.focused.background = "\${colors.primary}";
        label.focused.foreground = "\${colors.background}";
        label.focused.padding = 2;
        
        label.unfocused = "%index%";
        label.unfocused.background = "\${colors.background}";
        label.unfocused.foreground = "\${colors.foreground}";
        label.unfocused.padding = 2;
        
        label.visible = "%index%";
        label.visible.background = "\${colors.disabled}";
        label.visible.foreground = "\${colors.foreground}";
        label.visible.padding = 2;
        
        label.urgent = "%index%";
        label.urgent.background = "\${colors.alert}";
        label.urgent.foreground = "\${colors.background}";
        label.urgent.padding = 2;
      };

      # Window title module
      "module/xwindow" = {
        type = "internal/xwindow";
        label = "%title:0:60:...%";
        label.foreground = "\${colors.foreground}";
      };

      # PulseAudio module
      "module/pulseaudio" = {
        type = "internal/pulseaudio";
        
        format.volume = "<ramp-volume> <label-volume>";
        format.volume.prefix.foreground = "\${colors.primary}";
        
        label.volume = "%percentage%%";
        
        label.muted = "󰖁 muted";
        label.muted.foreground = "\${colors.disabled}";
        
        ramp.volume = ["" "" ""];
        
        click.right = "pavucontrol";
      };

      # Network module
      "module/network" = {
        type = "internal/network";
        interface.type = "wireless";
        
        interval = 5;
        
        format.connected = "<label-connected>";
        label.connected = " %essid%";
        label.connected.foreground = "\${colors.foreground}";
        
        format.disconnected = "<label-disconnected>";
        label.disconnected = "󰖪 disconnected";
        label.disconnected.foreground = "\${colors.disabled}";
      };

      # Date/Time module
      "module/date" = {
        type = "internal/date";
        interval = 1;
        
        date = "%a %b %d";
        time = "%I:%M %p";
        
        label = " %date%  %time%";
        label.foreground = "\${colors.foreground}";
      };

      # Global settings
      "settings" = {
        screenchange.reload = true;
        pseudo.transparency = true;
      };
    };
  };
}
