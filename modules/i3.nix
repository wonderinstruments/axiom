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
      bars = [ ];
    };
  };

}
