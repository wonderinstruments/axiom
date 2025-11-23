{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.admin.web;

in
{
  options = {
    axiom.admin.web = {
      firefox = {
        enable = lib.mkEnableOption "Enable firefox browser";
      };
      chromium = {
        enable = lib.mkEnableOption "Enable chromium browser";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.firefox.enable {
      programs.firefox.enable = true;
      xdg.desktopEntries.firefox = {
        name = "Firefox";
        comment = "Browse websites and search the internet";
        exec = "firefox";
        icon = "firefox";
        categories = [
          "Network"
          "WebBrowser"
        ];
        terminal = false;
        startupNotify = true;
      };
      xdg.dataFile."applications/rofi-firefox.desktop".text = ''
        [Desktop Entry]
        Version=1.0
        Type=Application
        Name=firefox
        Comment=Browse websites and search the internet
        Exec=firefox
        Icon=firefox
        Categories=Network;WebBrowser;RofiCustom;
        Terminal=false
        StartupNotify=true
      '';
      xdg.dataFile."applications/launcher-firefox.desktop".text = ''
        [Desktop Entry]
        Version=1.0
        Type=Application
        Name=firefox
        Comment=Browse websites and search the internet
        Exec=firefox
        Icon=firefox
        Categories=Network;WebBrowser;LauncherCustom;
        Terminal=false
        StartupNotify=true
      '';
    })
    (lib.mkIf cfg.chromium.enable {
      programs.chromium.enable = true;
      xdg.desktopEntries.chromium = {
        name = "Chromium";
        comment = "Browse websites and search the internet";
        exec = "chromium";
        icon = "chromium";
        categories = [
          "Network"
          "WebBrowser"
        ];
        terminal = false;
        startupNotify = true;
      };
      xdg.dataFile."applications/rofi-chromium.desktop".text = ''
        [Desktop Entry]
        Version=1.0
        Type=Application
        Name=chromium
        Comment=Browse websites and search the internet
        Exec=chromium
        Icon=chromium
        Categories=Network;WebBrowser;RofiCustom;
        Terminal=false
        StartupNotify=true
      '';
      xdg.dataFile."applications/launcher-chromium.desktop".text = ''
        [Desktop Entry]
        Version=1.0
        Type=Application
        Name=chromium
        Comment=Browse websites and search the internet
        Exec=chromium
        Icon=chromium
        Categories=Network;WebBrowser;LauncherCustom;
        Terminal=false
        StartupNotify=true
      '';
    })
  ];
}
