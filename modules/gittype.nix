{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.gittype;

  gittype = pkgs.stdenv.mkDerivation {
    pname = "gittype";
    version = "0.8.0";

    src = pkgs.fetchurl {
      url = "https://github.com/unhappychoice/gittype/releases/download/v0.8.0/gittype-v0.8.0-x86_64-unknown-linux-gnu.tar.gz";
      sha256 = "sha256-DS2kdXoob48bZdaSOLO8CPIccCcCcsuGtW49HFQaJQY=";
    };

    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/bin
      cp gittype $out/bin/
      chmod +x $out/bin/gittype
    '';
  };

in
{
  options.axiom.gittype = {
    enable = lib.mkEnableOption "GitType typing practice tool";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ gittype ];

    xdg.desktopEntries.gittype = {
      name = "GitType";
      genericName = "Typing Practice";
      comment = "Practice typing with git commit messages";
      exec = "${pkgs.kitty}/bin/kitty --hold ${gittype}/bin/gittype";
      icon = "utilities-terminal";
      terminal = false;
      categories = [
        "Game"
        "Education"
      ];
    };

    xdg.dataFile."applications/rofi-gittype.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Type=Application
      Name=GitType
      Comment=Practice typing with git commit messages
      Exec=${pkgs.kitty}/bin/kitty --hold ${gittype}/bin/gittype
      Icon=utilities-terminal
      Categories=Game;Education;RofiCustom;
      Terminal=false
      StartupNotify=true
    '';

    xdg.dataFile."applications/launcher-gittype.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Type=Application
      Name=GitType
      Comment=Practice typing with git commit messages
      Exec=${gittype}/bin/gittype
      Icon=utilities-terminal
      Categories=Game;Education;
      Terminal=false
      StartupNotify=true
    '';
  };
}
