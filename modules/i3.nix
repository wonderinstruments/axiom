{ pkgs, ... }:
{
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      startup = [
        {
          command = "i3-msg 'workspace 1; exec kitty'";
          always = false;
        }
      ];
    };
  };

}
