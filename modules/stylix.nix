{
  lib,
  config,
  pkgs,
  stylix,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.axiom.theme;
in
{
  options.axiom.theme = {
    colors = mkOption {
      type = types.enum [
        "rose-pine-moon"
        "everforest"
        "moonlight"
        "spaceduck"
        "woodland"
        "sandcastle"
        "selenized-dark"
        "tokyo-night-storm"
        "zenbones"
        "eris"
        "blueforest"
        "aztec"
        "zenburn"
      ];
      default = "tokyo-night-storm";
      description = "System theme colors";
    };
  };
  config = {
    stylix = {
      enable = true;
      targets.firefox.enable = false;

      base16Scheme = "${pkgs.base16-schemes}/share/themes/${cfg.colors}.yaml";

      fonts = {
        monospace = {
          package = pkgs.atkinson-hyperlegible-mono;
          name = "Atkinson Hyperlegible Mono";
        };
        sansSerif = {
          package = pkgs.atkinson-hyperlegible-next;
          name = "Atkinson Hyperlegible Next";
        };
      };
    };
  };
}
