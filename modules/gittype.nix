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

    xdg.desktopEntries.gittype = {
      name = "GitType";
      genericName = "Typing Practice";
      comment = "Practice typing with git commit messages";
      exec = "${pkgs.kitty}/bin/kitty --hold ${gittype.packages.${pkgs.system}.default}/bin/gittype";
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
      Exec=${pkgs.kitty}/bin/kitty --hold ${gittype.packages.${pkgs.system}.default}/bin/gittype
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
      Exec=${gittype.packages.${pkgs.system}.default}/bin/gittype
      Icon=utilities-terminal
      Categories=Game;Education;
      Terminal=false
      StartupNotify=true
    '';
  };
}
