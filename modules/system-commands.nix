{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = {
    home.packages = [
      (pkgs.writeShellScriptBin "axiom-docs" ''
        exec ${pkgs.glow}/bin/glow ~/docs
      '')
    ];
  };
}
