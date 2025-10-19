{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.admin;
in
{
  options = {
    axiom.admin = {
      webBrowser = {
        enable = lib.mkEnableOption "Enable firefox browser";
      };
    };
  };

  config = lib.mkIf cfg.webBrowser.enable {
    programs.firefox.enable = true;
  };
}
