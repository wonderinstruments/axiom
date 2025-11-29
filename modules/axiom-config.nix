# Axiom Config Module
#
# Copies HOCON config templates to ~/config/axiom/ if they don't exist.
# Users edit these files and run `axiom-rebuild` to apply changes.

{
  lib,
  pkgs,
  config,
  ...
}:

let
  templateDir = ../templates;
  canonicalDir = ".local/share/axiom/config-templates";
  userDir = "config/axiom";

  configFiles = [
    "config.conf"
    "admin.conf"
  ];

  # Map template names to their source paths
  templateSources = {
    "config.conf" = "${templateDir}/user-config.conf";
    "admin.conf" = "${templateDir}/admin-config.conf";
  };

  # Create canonical file entries (always overwritten by Nix)
  mkCanonicalFile =
    name:
    lib.nameValuePair "${canonicalDir}/${name}" {
      source = templateSources.${name};
      force = true;
    };

  configListForShell = lib.concatStringsSep " " configFiles;
in
{
  config = {
    # Canonical copies from repository (always overwrite)
    home.file = builtins.listToAttrs (map mkCanonicalFile configFiles);

    # Copy to user dir if missing
    home.activation.axiomConfigInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      mkdir -p "$HOME/${userDir}"
      mkdir -p "$HOME/${canonicalDir}"

      echo "Checking for missing Axiom config files in ~/${userDir}..."
      for f in ${configListForShell}; do
        src="$HOME/${canonicalDir}/$f"
        dest="$HOME/${userDir}/$f"
        if [ ! -e "$dest" ] && [ -e "$src" ]; then
          run cp -fL "$src" "$dest"
          echo "  Installed config: $f"
        fi
      done
    '';
  };
}
