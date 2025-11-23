{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.docs;
  docsDir = ../docs;
  entries = builtins.readDir docsDir;
  docNames = builtins.attrNames entries;
  mdDocs = builtins.filter (name: lib.hasSuffix ".md" name) docNames;
  defaultCanonicalDir = ".local/share/axiom/docs";
  docListForShell = lib.concatStringsSep " " mdDocs;
  toSourcePath = name: builtins.toPath "${docsDir}/${name}";
  mkCanonicalFile =
    name:
    lib.nameValuePair "${cfg.canonicalDir}/${name}" {
      source = toSourcePath name;
      force = true;
    };
in
{
  options.axiom.docs = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable deployment of documentation files.";
    };

    userDir = lib.mkOption {
      type = lib.types.str;
      default = "docs";
      description = "Relative path under $HOME where user-editable docs live.";
    };

    canonicalDir = lib.mkOption {
      type = lib.types.str;
      default = defaultCanonicalDir;
      description = "Relative path under $HOME for canonical doc copies (always overwritten).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure directories exist and populate missing user copies from canonical
    home.activation.docsInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      mkdir -p "$HOME/${cfg.userDir}"
      mkdir -p "$HOME/${cfg.canonicalDir}"

      echo "Checking for missing docs in ~/${cfg.userDir}..."
      for f in ${docListForShell}; do
        src="$HOME/${cfg.canonicalDir}/$f"
        dest="$HOME/${cfg.userDir}/$f"
        if [ ! -e "$dest" ] && [ -e "$src" ]; then
          run cp -f "$src" "$dest"
          echo "  Installed missing doc: $f"
        fi
      done
    '';

    # Canonical copies from repository (always overwrite)
    home.file = builtins.listToAttrs (map mkCanonicalFile mdDocs);
  };
}
