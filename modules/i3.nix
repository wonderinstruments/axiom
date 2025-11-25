{ config, pkgs, ... }:
{
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      window.commands = [
        {
          command = "fullscreen enable";
          criteria = {
            title = "parental-controls";
          };
        }
        {
          command = "fullscreen enable; border pixel 0";
          criteria = {
            title = "^cmatrix-saver-[0-9]+$";
          };
        }
      ];
      startup = [
        {
          command = "i3-msg 'workspace 1; exec kitty'";
          always = false;
        }
        {
          command = "xset s off -dpms s noblank";
          always = false;
          notification = false;
        }
        {
          command = "systemctl --user restart polybar";
          always = true;
          notification = false;
        }
      ];
      gaps = {
        inner = config.axiom.theme.windows.gap.size;
      };
      # Disabled in favor of polybar
      bars = [ ];
    };
  };

}
