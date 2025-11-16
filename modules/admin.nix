{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.admin;

  # Map of admin applications to Nix packages
  adminApplications = {
    warp-terminal = {
      package = pkgs.warp-terminal;
      exec = "warp-terminal";
      icon = "warp";
      comment = "Warp Terminal";
      categories = [
        "System"
        "TerminalEmulator"
      ];
    };
    spotify = {
      package = pkgs.spotify;
      exec = "spotify";
      icon = "spotify";
      comment = "Music Streaming";
      categories = [
        "AudioVideo"
        "Audio"
      ];
    };
    obsidian = {
      package = pkgs.obsidian;
      exec = "obsidian";
      icon = "obsidian";
      comment = "Knowledge Base";
      categories = [
        "Office"
      ];
    };
    slack = {
      package = pkgs.slack;
      exec = "slack";
      icon = "slack";
      comment = "Team Communication";
      categories = [
        "Network"
        "InstantMessaging"
      ];
    };
    discord = {
      package = pkgs.discord;
      exec = "discord";
      icon = "discord";
      comment = "Voice and Text Chat";
      categories = [
        "Network"
        "InstantMessaging"
      ];
    };
  };

  # Filter enabled applications
  enabledApps = lib.filterAttrs (name: _: cfg.${name}.enable) adminApplications;

in
{
  options = {
    axiom.admin = {
      webBrowser = {
        enable = lib.mkEnableOption "Enable firefox browser";
      };
      chromium = {
        enable = lib.mkEnableOption "Enable chromium browser";
      };
      warp-terminal = {
        enable = lib.mkEnableOption "Enable Warp Terminal";
      };
      spotify = {
        enable = lib.mkEnableOption "Enable Spotify";
      };
      obsidian = {
        enable = lib.mkEnableOption "Enable Obsidian";
      };
      slack = {
        enable = lib.mkEnableOption "Enable Slack";
      };
      discord = {
        enable = lib.mkEnableOption "Enable Discord";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.webBrowser.enable {
      programs.firefox.enable = true;
      xdg.desktopEntries.firefox = {
        name = "Firefox";
        comment = "Web Browser";
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
        Comment=Web Browser
        Exec=firefox
        Icon=firefox
        Categories=Network;WebBrowser;RofiCustom;
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
    })
    {
      # Install enabled admin applications
      home.packages = lib.attrValues (lib.mapAttrs (_: app: app.package) enabledApps);

      # Create desktop entries for enabled applications
      xdg.desktopEntries = lib.mapAttrs (name: app: {
        name = lib.strings.toUpper (lib.substring 0 1 name) + lib.substring 1 (-1) name;
        comment = app.comment;
        exec = app.exec;
        icon = app.icon;
        categories = app.categories;
        terminal = false;
        startupNotify = true;
      }) enabledApps;

      # Create rofi-specific desktop entries (RofiCustom category)
      xdg.dataFile = lib.mapAttrs' (name: app: {
        name = "applications/rofi-${name}.desktop";
        value = {
          text = ''
            [Desktop Entry]
            Version=1.0
            Type=Application
            Name=${name}
            Comment=${app.comment}
            Exec=${app.exec}
            Icon=${app.icon}
            Categories=${lib.concatStringsSep ";" app.categories};RofiCustom;
            Terminal=false
            StartupNotify=true
          '';
        };
      }) enabledApps;
    }
  ];
}
