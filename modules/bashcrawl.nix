{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.bashcrawl;

  # Download bashcrawl from GitLab
  bashcrawlSrc = pkgs.fetchFromGitLab {
    owner = "slackermedia";
    repo = "bashcrawl";
    rev = "stable-2024.02.09";
    sha256 = "sha256-/L3pbyhVlDoorU5fQmLpLIiY0m6NIYeP121PgDVfS7U=";
  };

  defaultCanonicalDir = ".local/share/axiom/bashcrawl";
in
{
  options.axiom.bashcrawl = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install bashcrawl to user directory with pristine backup.";
    };

    userDir = lib.mkOption {
      type = lib.types.str;
      default = "bashcrawl";
      description = "Relative path under $HOME where user-editable bashcrawl lives.";
    };

    canonicalDir = lib.mkOption {
      type = lib.types.str;
      default = defaultCanonicalDir;
      description = "Relative path under $HOME for canonical bashcrawl copy (always overwritten).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure directories exist and populate user copy from canonical if missing
    home.activation.bashcrawlInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      mkdir -p "$HOME/${cfg.canonicalDir}"

      echo "Checking for bashcrawl in ~/${cfg.userDir}..."
      if [ ! -e "$HOME/${cfg.userDir}" ]; then
        if [ -e "$HOME/${cfg.canonicalDir}/entrance" ]; then
          run cp -r "$HOME/${cfg.canonicalDir}" "$HOME/${cfg.userDir}"
          echo "  Installed bashcrawl from canonical copy"
        fi
      fi
    '';

    # Canonical copy from Nix store (always overwrite)
    home.file."${cfg.canonicalDir}" = {
      source = bashcrawlSrc;
      recursive = true;
      force = true; # always overwrite canonical copy
    };
  };
}
