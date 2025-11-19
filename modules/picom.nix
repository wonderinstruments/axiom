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
      shadow-radius = 60;
      shadow-color = "#${config.lib.stylix.colors.base0D}";
      shadow-offset-x = -60;
      shadow-offset-y = -60;
    };
    opacityRules = [
      "100:class_g = 'Rofi'"
      "95:class_g = 'Polybar'"
    ];
  };
}
