{ config, pkgs, ... }:
{
  services.picom = {
    enable = true;
    fade = true;
    inactiveOpacity = 0.9;
    shadow = true;
    shadowExclude = [
      "class_g = 'Polybar'"
    ];
    settings = {
      shadow-radius = 50;
      shadow-color = "#${config.lib.stylix.colors.base0D}";
      shadow-offset-x = -50;
      shadow-offset-y = -50;
      shadow-ignore-shaped = false;
    };
    opacityRules = [
      "100:class_g = 'Rofi'"
      "90:class_g = 'Polybar'"
    ];
  };
}
