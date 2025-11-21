{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.python-scripts;
  scriptDir = ../scripts;
  entries = builtins.readDir scriptDir;
  scriptNames = builtins.attrNames entries;
  pyScripts = builtins.filter (name: lib.hasSuffix ".py" name) scriptNames;
  defaultCanonicalDir = ".local/share/axiom/python-scripts";
  # Join a list with spaces for shell loop usage
  pyListForShell = lib.concatStringsSep " " pyScripts;
  toSourcePath = name: builtins.toPath "${scriptDir}/${name}";
  mkCanonicalFile = name:
    lib.nameValuePair "${cfg.canonicalDir}/${name}" {
      source = toSourcePath name;
      executable = true;
      force = true; # always overwrite canonical copies
    };
in
{
  options.axiom.python-scripts = {
    enable = lib.mkEnableOption "install python scripts to user scripts dir and canonical location";

    userDir = lib.mkOption {
      type = lib.types.str;
      default = "scripts";
      description = "Relative path under $HOME where user-editable scripts live.";
    };

    canonicalDir = lib.mkOption {
      type = lib.types.str;
      default = defaultCanonicalDir;
      description = "Relative path under $HOME for canonical script copies (always overwritten).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure directories exist and populate missing user copies from canonical
    home.activation.pythonScriptsInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      mkdir -p "$HOME/${cfg.userDir}"
      mkdir -p "$HOME/${cfg.canonicalDir}"

      for f in ${pyListForShell}; do
        src="$HOME/${cfg.canonicalDir}/$f"
        dest="$HOME/${cfg.userDir}/$f"
        if [ ! -e "$dest" ] && [ -e "$src" ]; then
          cp -f "$src" "$dest"
          chmod +x "$dest"
        fi
      done
    '';

    # Canonical copies from repository (always overwrite)
    home.file = builtins.listToAttrs (map mkCanonicalFile pyScripts);
  };
}