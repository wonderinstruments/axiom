{ pkgs, ... }:
{
  services.xserver.enable = true;
  services.xserver.desktopManager = {
    xterm.enable = false;
    xfce = {
      enable = true;
      noDesktop = true;
      enableXfwm = false;
      enableScreensaver = false;
    };
  };
  services.xserver.windowManager.i3 = {
    enable = true;
    extraPackages = with pkgs; [
      dmenu
      i3status
      pasystray
    ];
  };
  services.displayManager.defaultSession = "xfce+i3";
}
