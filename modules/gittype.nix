{
  lib,
  pkgs,
  config,
  gittype,
  ...
}:
let
  cfg = config.axiom.gittype;

in
{
  options.axiom.gittype = {
    enable = lib.mkEnableOption "GitType typing practice tool";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ gittype.packages.${pkgs.system}.default ];

    home.file.".gittype/config.json".text = builtins.toJSON {
      theme = {
        current_theme_id = "ascii";
      };
    };
  };
}
