{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.terminal;
in
{
  options = {
    axiom.terminal = {
      fontSize = lib.mkOption {
        type = lib.types.int;
        default = 12;
        description = "Font size for kitty terminal";
      };
    };
  };

  config = {
    programs.kitty = {
      enable = true;
      shellIntegration.enableFishIntegration = true;
      settings = {
        shell = "${pkgs.fish}/bin/fish";
        font_size = cfg.fontSize;
      };
    };
  };
}
