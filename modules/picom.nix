{
  config,
  pkgs,
  lib,
  ...
}:
let
  shadowSize = config.axiom.theme.windows.shadow.size;
  shadowEnabled = shadowSize > 0;
in
{
  services.picom = {
    enable = true;
    fade = true;
    inactiveOpacity = 0.9;
    shadow = shadowEnabled;
    shadowExclude = lib.mkIf shadowEnabled [
      "class_g = 'Polybar'"
    ];
    settings = lib.mkIf shadowEnabled {
      shadow-radius = shadowSize;
      shadow-color = "#${config.lib.stylix.colors.base0D}";
      shadow-offset-x = -1 * shadowSize;
      shadow-offset-y = -1 * shadowSize;
    };
    opacityRules = [
      "100:class_g = 'Rofi'"
      "95:class_g = 'Polybar'"
      "90:name *= 'cmatrix-saver'"
    ];
  };
}
