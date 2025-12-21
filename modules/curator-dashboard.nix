{
  lib,
  pkgs,
  config,
  axiom-connect,
  ...
}:
let
  cfg = config.axiom.curator-dashboard;

in
{
  options.axiom.curator-dashboard = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Curator Dashboard";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ axiom-connect.packages.${pkgs.system}.curator-dashboard ];
  };
}
