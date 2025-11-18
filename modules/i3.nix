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
      ];
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
        {
          command = "systemctl --user restart polybar";
          always = true;
          notification = false;
        }
      ];
      gaps = {
        inner = 40;
      };
      # Disabled in favor of polybar
      bars = [ ];
    };
  };

}
