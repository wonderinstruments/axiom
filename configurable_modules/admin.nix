{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.admin;
in
{
  options = {
    admin = {
      webBrowser = {
        enable = lib.mkEnableOption "Enable firefox browser";
      };
    };
  };

  config = lib.mkIf cfg.webBrowser.enable {
    programs.firefox.enable = true;
  };
}
