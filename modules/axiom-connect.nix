{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.axiom-connect;

in
{
  options.axiom.axiom-connect = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Axiom Connect agent";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.axiom-connect ];
  };
}
