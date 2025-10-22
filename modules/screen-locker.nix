{ pkgs, ... }:
{
  services.screen-locker = {
    enable = true;
    inactiveInterval = 1;
    lockCmd = "cmatrix";
    xautolock = {
      enable = true;
      detectSleep = true;
    };
  };
}
