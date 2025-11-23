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

  # Package the launcher script
  bashcrawl-launcher = pkgs.writeShellScriptBin "bashcrawl-launcher" ''
    exec ${pkgs.bash}/bin/bash ${../scripts/bashcrawl-launcher.sh}
  '';
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
    # Add launcher to PATH
    home.packages = [ bashcrawl-launcher ];

    # Regular desktop entry
    xdg.desktopEntries.bashcrawl = {
      name = "Bashcrawl";
      genericName = "Terminal Adventure Game";
      comment = "Learn terminal commands by exploring a text-based dungeon";
      exec = "${pkgs.kitty}/bin/kitty --hold ${bashcrawl-launcher}/bin/bashcrawl-launcher";
      icon = "bashcrawl";
      terminal = false;
      categories = [
        "Game"
        "Education"
      ];
    };

    # Rofi-specific desktop entry
    xdg.dataFile."applications/rofi-bashcrawl.desktop" = {
      text = ''
        [Desktop Entry]
        Version=1.0
        Type=Application
        Name=Bashcrawl
        Comment=Learn terminal commands by exploring a text-based dungeon
        Exec=${pkgs.kitty}/bin/kitty --hold ${bashcrawl-launcher}/bin/bashcrawl-launcher
        Icon=bashcrawl
        Categories=Game;Education;RofiCustom;
        Terminal=false
        StartupNotify=true
      '';
    };
    xdg.dataFile."applications/launcher-bashcrawl.desktop" = {
      text = ''
        [Desktop Entry]
        Version=1.0
        Type=Application
        Name=Bashcrawl
        Comment=Learn terminal commands by exploring a text-based dungeon
        Exec=${bashcrawl-launcher}/bin/bashcrawl-launcher
        Icon=bashcrawl
        Categories=Development;
        Terminal=false
        StartupNotify=true
      '';
    };

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
