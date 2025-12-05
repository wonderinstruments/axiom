{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.admin.web;

  # Determine default browser (priority order)
  defaultBrowser =
    if cfg.librewolf.enable then
      "librewolf.desktop"
    else if cfg.mullvad-browser.enable then
      "mullvad-browser.desktop"
    else if cfg.firefox.enable then
      "firefox.desktop"
    else if cfg.chromium.enable then
      "chromium-browser.desktop"
    else
      null;

  browserMimeTypes = lib.optionalAttrs (defaultBrowser != null) {
    "text/html" = defaultBrowser;
    "x-scheme-handler/http" = defaultBrowser;
    "x-scheme-handler/https" = defaultBrowser;
    "x-scheme-handler/about" = defaultBrowser;
    "x-scheme-handler/unknown" = defaultBrowser;
  };

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
      librewolf = {
        enable = lib.mkEnableOption "Enable librewolf browser";
      };
      mullvad-browser = {
        enable = lib.mkEnableOption "Enable mullvad-browser";
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
    (lib.mkIf cfg.librewolf.enable {
      home.packages = [ pkgs.librewolf ];
      xdg.desktopEntries.librewolf = {
        name = "Librewolf";
        comment = "A privacy oriented web browser";
        exec = "librewolf";
        icon = "librewolf";
        categories = [
          "Network"
          "WebBrowser"
        ];
        terminal = false;
        startupNotify = true;
      };
      xdg.dataFile."applications/rofi-librewolf.desktop".text = ''
        [Desktop Entry]
        Version=1.0
        Type=Application
        Name=librewolf
        Comment=A privacy oriented web browser
        Exec=librewolf
        Icon=librewolf
        Categories=Network;WebBrowser;RofiCustom;
        Terminal=false
        StartupNotify=true
      '';
      xdg.dataFile."applications/launcher-librewolf.desktop".text = ''
        [Desktop Entry]
        Version=1.0
        Type=Application
        Name=librewolf
        Comment=A privacy oriented web browser
        Exec=librewolf
        Icon=librewolf
        Categories=Network;WebBrowser;LauncherCustom;
        Terminal=false
        StartupNotify=true
      '';
    })
    (lib.mkIf cfg.mullvad-browser.enable {
      home.packages = [ pkgs.mullvad-browser ];
      xdg.desktopEntries.mullvad-browser = {
        name = "Mullvad-browser";
        comment = "A very privacy oriented web browser";
        exec = "mullvad-browser";
        icon = "mullvad-browser";
        categories = [
          "Network"
          "WebBrowser"
        ];
        terminal = false;
        startupNotify = true;
      };
      xdg.dataFile."applications/rofi-mullvad-browser.desktop".text = ''
        [Desktop Entry]
        Version=1.0
        Type=Application
        Name=mullvad-browser
        Comment=A very privacy oriented web browser
        Exec=mullvad-browser
        Icon=mullvad-browser
        Categories=Network;WebBrowser;RofiCustom;
        Terminal=false
        StartupNotify=true
      '';
      xdg.dataFile."applications/launcher-mullvad-browser.desktop".text = ''
        [Desktop Entry]
        Version=1.0
        Type=Application
        Name=mullvad-browser
        Comment=A very privacy oriented web browser
        Exec=mullvad-browser
        Icon=mullvad-browser
        Categories=Network;WebBrowser;LauncherCustom;
        Terminal=false
        StartupNotify=true
      '';
    })
    # Set default browser MIME types
    { xdg.mimeApps.defaultApplications = browserMimeTypes; }
  ];
}
