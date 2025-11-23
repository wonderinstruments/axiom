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
        comment = "Web Browser";
        exec = "firefox";
        icon = "firefox";
        categories = [
          "Web"
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
        Comment=Web Browser
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
        Comment=Web Browser
        Exec=firefox
        Icon=firefox
        Categories=Web;Network;WebBrowser;LauncherCustom;
        Terminal=false
        StartupNotify=true
      '';
    })
    (lib.mkIf cfg.chromium.enable {
      programs.chromium.enable = true;
      xdg.desktopEntries.chromium = {
        name = "Chromium";
        comment = "Web Browser";
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
        Comment=Web Browser
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
        Comment=Web Browser
        Exec=chromium
        Icon=chromium
        Categories=Web;Network;WebBrowser;LauncherCustom;
        Terminal=false
        StartupNotify=true
      '';
    })
  ];
}
