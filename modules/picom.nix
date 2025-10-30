{ pkgs, ... }:
{
  services.picom = {
    enable = true;
    fade = true;
    inactiveOpacity = 0.8;
    shadow = true;
    settings = {
      shadow-radius = 20;
      shadow-color = "#00bfff";
    };
  };
}
