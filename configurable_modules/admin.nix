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
  options.webBrowser = {
    enable = lib.mkEnableOption "Enable firefox browser";
  };

  config = lib.mkIf cfg.webBrowser.enable {
    programs.firefox.enable = true;
  };
}
