{
  config,
  lib,
  pkgs,
  ...
}:

let
  axiom-reset-config = pkgs.writeShellScriptBin "axiom-reset-config" (
    builtins.readFile ../scripts/axiom-reset-config.sh
  );
in
{
  config = {
    home.packages = [
      (pkgs.writeShellScriptBin "axiom-docs" ''
        exec ${pkgs.glow}/bin/glow ~/docs
      '')
      axiom-reset-config
    ];
  };
}
