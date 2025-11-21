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
  mkCanonicalFile =
    name:
    lib.nameValuePair "${cfg.canonicalDir}/${name}" {
      source = toSourcePath name;
      executable = true;
      force = true; # always overwrite canonical copies
    };

  # Package restore_scripts.py as a command-line tool
  restore-scripts = pkgs.writeShellScriptBin "restore-scripts" ''
    exec ${pkgs.python3}/bin/python3 ${../scripts/restore_scripts.py} "$@"
  '';
in
{
  options.axiom.python-scripts = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install python scripts to user scripts dir and canonical location.";
    };

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
    # Add restore-scripts to user's PATH
    home.packages = [ restore-scripts ];

    # Ensure directories exist and populate missing user copies from canonical
    home.activation.pythonScriptsInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      mkdir -p "$HOME/${cfg.userDir}"
      mkdir -p "$HOME/${cfg.canonicalDir}"

      echo "Checking for missing Python scripts in ~/${cfg.userDir}..."
      for f in ${pyListForShell}; do
        src="$HOME/${cfg.canonicalDir}/$f"
        dest="$HOME/${cfg.userDir}/$f"
        if [ ! -e "$dest" ] && [ -e "$src" ]; then
          run cp -f "$src" "$dest"
          run chmod +x "$dest"
          echo "  Installed missing script: $f"
        fi
      done
    '';

    # Canonical copies from repository (always overwrite)
    home.file = builtins.listToAttrs (map mkCanonicalFile pyScripts);
  };
}
