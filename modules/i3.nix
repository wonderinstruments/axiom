{ config, pkgs, ... }:
{
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      startup = [
        {
          command = "i3-msg 'workspace 1; exec kitty'";
          always = false;
        }
        {
          command = "exec pasystray";
          always = false;
          notification = false;
        }
        {
          command = "exec --no-startup-id xset s off -dpms s noblank";
          always = false;
          notification = false;
        }
      ];
      gaps = {
        inner = 50;
      };
      bars = [
        {
          id = "bottom";
          mode = "dock";
          position = "bottom";
          fonts = {
            names = [ "pango:Atkinson Hyperlegible Next" ];
            style = "Bold";
            size = 14.0;
          };
          extraConfig = ''
            	    workspace_min_width 60
            	  '';
          colors = {
            background = "#${config.lib.stylix.colors.base00}";
            statusline = "#${config.lib.stylix.colors.base05}";
            separator = "#${config.lib.stylix.colors.base03}";
            focusedWorkspace = {
              border = "#${config.lib.stylix.colors.base0D}";
              background = "#${config.lib.stylix.colors.base0D}";
              text = "#${config.lib.stylix.colors.base00}";
            };
            activeWorkspace = {
              border = "#${config.lib.stylix.colors.base03}";
              background = "#${config.lib.stylix.colors.base03}";
              text = "#${config.lib.stylix.colors.base05}";
            };
            inactiveWorkspace = {
              border = "#${config.lib.stylix.colors.base01}";
              background = "#${config.lib.stylix.colors.base01}";
              text = "#${config.lib.stylix.colors.base05}";
            };
            urgentWorkspace = {
              border = "#${config.lib.stylix.colors.base08}";
              background = "#${config.lib.stylix.colors.base08}";
              text = "#${config.lib.stylix.colors.base00}";
            };
            bindingMode = {
              border = "#${config.lib.stylix.colors.base0A}";
              background = "#${config.lib.stylix.colors.base0A}";
              text = "#${config.lib.stylix.colors.base00}";
            };
          };
        }
      ];
    };
  };

}
