{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

let
  appsCfg = config.axiom.admin.applications;
  gamesCfg = config.axiom.admin.games;

  # Games
  games = {
    freeciv = {
      package = pkgs.freeciv;
      exec = "freeciv-gtk3.22";
      icon = "freeciv";
      comment = "Freeciv";
      categories = [
        "Game"
      ];
    };
    widelands = {
      package = pkgs.widelands;
      exec = "widelands";
      icon = "widelands";
      comment = "Widelands";
      categories = [
        "Game"
      ];
    };
    the-powder-toy = {
      package = pkgs.the-powder-toy;
      exec = "powder";
      icon = "the-powder-toy";
      comment = "The Powder Toy";
      categories = [
        "Game"
      ];
    };
    luanti = {
      package = pkgs.luanti;
      exec = "luanti";
      icon = "luanti";
      comment = "Luanti";
      categories = [
        "Game"
      ];
    };
    zeroad = {
      package = pkgs.zeroad;
      exec = "zeroad";
      icon = "zeroad";
      comment = "0 A.D.";
      categories = [
        "Game"
      ];
    };
    openttd = {
      package = pkgs.openttd;
      exec = "openttd";
      icon = "openttd";
      comment = "OpenTTD";
      categories = [
        "Game"
      ];
    };
    katomic = {
      package = pkgs.kdePackages.katomic;
      exec = "katomic";
      icon = "katomic";
      comment = "KAtomic";
      categories = [
        "Game"
      ];
    };
    mindustry = {
      package = pkgs.mindustry;
      exec = "mindustry";
      icon = "mindustry";
      comment = "Mindustry";
      categories = [
        "Game"
      ];
    };
    endless-sky = {
      package = pkgs.endless-sky;
      exec = "endless-sky";
      icon = "endless-sky";
      comment = "Endless Sky";
      categories = [
        "Game"
      ];
    };
    pingus = {
      package = pkgs.pingus;
      exec = "pingus";
      icon = "pingus";
      comment = "Lemmings-like puzzle game";
      categories = [
        "Game"
        "ArcadeGame"
      ];
    };
    tuxtype = {
      package = pkgs.tuxtype;
      exec = "tuxtype";
      icon = "tuxtype";
      comment = "Educational Typing Tutor Game";
      categories = [
        "Game"
        "Education"
      ];
    };
  };

  # Map of Ansible applications to Nix packages where available
  nixApplications = {
    # Admin Applications
    warp-terminal = {
      package = pkgs.warp-terminal;
      exec = "warp-terminal";
      icon = "warp";
      comment = "Warp Terminal";
      categories = [
        "Development"
        "System"
        "TerminalEmulator"
      ];
      enableOption = true;
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
      enableOption = true;
    };
    obsidian = {
      package = pkgs.obsidian;
      exec = "obsidian";
      icon = "obsidian";
      comment = "Knowledge Base";
      categories = [
        "Office"
      ];
      enableOption = true;
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
      enableOption = true;
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
      enableOption = true;
    };

    # Text Editors & Writing
    vimiv = {
      package = pkgs.vimiv-qt;
      exec = "vimiv";
      icon = "vimiv";
      comment = "Image Viewer";
      categories = [
        "Utility"
        "Graphics"
      ];
    };
    zathura = {
      package = pkgs.zathura;
      exec = "zathura";
      icon = "zathura";
      comment = "PDF Reader";
      categories = [
        "Utility"
        "Office"
      ];
    };
    ghostwriter = {
      package = pkgs.kdePackages.ghostwriter;
      exec = "ghostwriter";
      icon = "ghostwriter";
      comment = "Markdown Editor";
      categories = [
        "Office"
        "WordProcessor"
      ];
    };
    freeplane = {
      package = pkgs.freeplane;
      exec = "freeplane";
      icon = "freeplane";
      comment = "Mind Maps";
      categories = [
        "Office"
      ];
    };

    # Information & Education
    xiphos = {
      package = pkgs.xiphos;
      exec = "xiphos";
      icon = "xiphos";
      comment = "Bible Study";
      categories = [
        "Education"
      ];
      enableOption = true;
    };
    anki = {
      package = pkgs.anki;
      exec = "anki";
      icon = "anki";
      comment = "Flashcards";
      categories = [
        "Office"
      ];
    };
    stellarium = {
      package = pkgs.stellarium;
      exec = "stellarium";
      icon = "stellarium";
      comment = "Desktop Planetarium";
      categories = [
        "Education"
        "Science"
        "Astronomy"
      ];
    };
    celestia = {
      package = pkgs.celestia;
      exec = "celestia";
      icon = "celestia";
      comment = "Real-time 3D visualization of space";
      categories = [
        "Education"
        "Science"
        "Astronomy"
      ];
    };
    kstars = {
      package = pkgs.kstars;
      exec = "kstars";
      icon = "kstars";
      comment = "Desktop Planetarium";
      categories = [
        "Education"
        "Science"
        "Astronomy"
      ];
    };
    marble = {
      package = pkgs.kdePackages.marble;
      exec = "marble";
      icon = "marble";
      comment = "Virtual Globe and World Atlas";
      categories = [
        "Education"
        "Geography"
      ];
    };

    # Creativity
    pinta = {
      package = pkgs.pinta;
      exec = "pinta";
      icon = "pinta";
      comment = "Drawing";
      categories = [
        "Graphics"
      ];
    };
    shotcut = {
      package = pkgs.shotcut;
      exec = "shotcut";
      icon = "shotcut";
      comment = "Video editor";
      categories = [
        "Video"
        "AudioVideo"
      ];
    };
    kwave = {
      package = pkgs-unstable.kdePackages.kwave;
      exec = "kwave";
      icon = "kwave";
      comment = "Audio Editor";
      categories = [
        "Utility"
        "AudioVideo"
      ];
    };
    rosegarden = {
      package = pkgs.rosegarden;
      exec = "rosegarden";
      icon = "rosegarden";
      comment = "Audio composer";
      categories = [
        "Audio"
        "AudioVideo"
      ];
    };
    easyeffects = {
      package = pkgs.easyeffects;
      exec = "easyeffects";
      icon = "easyeffects";
      comment = "Audio Effects";
      categories = [
        "Audio"
        "AudioVideo"
      ];
    };
    vlc = {
      package = pkgs.vlc;
      exec = "vlc";
      icon = "vlc";
      comment = "AudioVideo Player";
      categories = [
        "Utility"
        "AudioVideo"
      ];
    };
    helm = {
      package = pkgs.helm;
      exec = "helm";
      icon = "helm";
      comment = "Polyphonic Synthesizer";
      categories = [
        "Audio"
        "AudioVideo"
      ];
    };
    lmms = {
      package = pkgs.lmms;
      exec = "lmms";
      icon = "lmms";
      comment = "Digital Audio Workstation";
      categories = [
        "Audio"
        "AudioVideo"
        "Sequencer"
      ];
    };
    krita = {
      package = pkgs.krita;
      exec = "krita";
      icon = "krita";
      comment = "Digital Painting Application";
      categories = [
        "Graphics"
        "2DGraphics"
        "RasterGraphics"
      ];
    };
    tuxpaint = {
      package = pkgs.tuxpaint;
      exec = "tuxpaint";
      icon = "tuxpaint";
      comment = "Drawing Program for Children";
      categories = [
        "Graphics"
      ];
    };
    # coding
    thonny = {
      package = pkgs.thonny;
      exec = "thonny";
      icon = "thonny";
      comment = "Python Coding Environment";
      categories = [
        "Development"
      ];
    };

    # TUI Applications
    tttui = {
      package = pkgs.stdenv.mkDerivation rec {
        pname = "tttui";
        version = "unstable-2024-01-01";

        src = pkgs.fetchFromGitHub {
          owner = "reidoboss";
          repo = "tttui";
          rev = "main";
          sha256 = "sha256-pCN5xBsKfva13nJk/1EDB+uK4qJWwXGogDiSFrkPd4Y=";
        };

        buildInputs = [ pkgs.python3 ];

        installPhase = ''
          mkdir -p $out/bin $out/lib
          cp -r tttui $out/lib/
          cp bin/tttui $out/bin/tttui
          chmod +x $out/bin/tttui

          # Fix the PYTHONPATH in the wrapper script
          substituteInPlace $out/bin/tttui \
            --replace 'PROJECT_ROOT=$(dirname "$SCRIPT_DIR")' "PROJECT_ROOT=$out/lib" \
            --replace '"$PYTHON_CMD"' '${pkgs.python3}/bin/python3'
        '';

        meta = with pkgs.lib; {
          description = "Tic-tac-toe terminal user interface";
          homepage = "https://github.com/reidoboss/tttui";
          license = licenses.mit;
          platforms = platforms.linux;
        };
      };
      exec = "tttui";
      icon = "utilities-terminal";
      comment = "Tic-Tac-Toe Game";
      categories = [
        "Game"
      ];
      isTui = true;
    };
    nmtui = {
      # No package specified: we only create desktop entries and do not
      # add anything to home.packages. Assumes nmtui is available on PATH
      # (e.g. from the system profile or another module).
      exec = "nmtui";
      icon = "network-workgroup";
      comment = "Network Manager TUI";
      categories = [
        "Network"
        "Settings"
      ];
      isTui = true;
    };
    glow = {
      package = pkgs.glow;
      exec = "glow ~/docs";
      icon = "glow";
      comment = "Docs Reader";
      categories = [
        "System"
      ];
      isTui = true;
      hideFromRofi = true;
    };
    dua = {
      package = pkgs.dua;
      exec = "dua i";
      icon = "dua";
      comment = "Disk Usage Analyzer";
      categories = [
        "System"
        "FileManager"
      ];
      isTui = true;
    };
    xplr = {
      package = pkgs.xplr;
      exec = "xplr";
      icon = "xplr";
      comment = "File Explorer";
      categories = [
        "System"
        "FileManager"
      ];
      isTui = true;
    };
    htop = {
      package = pkgs.htop-vim;
      exec = "htop";
      icon = "htop";
      comment = "Process Monitor";
      categories = [
        "System"
      ];
      isTui = true;
    };
    television = {
      package = pkgs.television;
      exec = "tv";
      icon = "television";
      comment = "Fuzzy Finder";
      categories = [
        "System"
      ];
      isTui = true;
    };
    broot = {
      package = pkgs.broot;
      exec = "broot";
      icon = "broot";
      comment = "Tree based file explorer";
      categories = [
        "System"
      ];
      isTui = true;
    };
    visidata = {
      package = pkgs.visidata;
      exec = "visidata";
      icon = "visidata";
      comment = "Terminal Spreadsheet";
      categories = [
        "Office"
      ];
      isTui = true;
    };
    lazygit = {
      package = pkgs.lazygit;
      exec = "lazygit";
      icon = "lazygit";
      comment = "Git Terminal UI";
      categories = [
        "Development"
      ];
      isTui = true;
      hideFromRofi = true;
    };
    play = {
      package = pkgs.writeShellScriptBin "play-launcher" ''
        CMD=$(echo -e "awk\ngrep\nsed\njq\nyq" | fzf --prompt="Select command: ")
        if [ -n "$CMD" ]; then
          play "$CMD"
        fi
      '';
      exec = "play-launcher";
      icon = "play";
      comment = "Command Practice Tool";
      categories = [
        "Development"
      ];
      isTui = true;
    };
  };

  # Separate applications into those with and without enable options
  appsWithEnableOption = lib.filterAttrs (_: app: app.enableOption or false) nixApplications;
  appsWithoutEnableOption = lib.filterAttrs (_: app: !(app.enableOption or false)) nixApplications;

  # Filter enabled applications (only applies to apps with enableOption flag)
  enabledApps = lib.filterAttrs (name: _: appsCfg.${name}.enable) appsWithEnableOption;

  # Filter enabled games
  enabledGames = lib.filterAttrs (name: _: gamesCfg.${name}.enable) games;

  # Merge enabled apps with apps that don't require enable options, plus enabled games
  allActiveApps = enabledApps // appsWithoutEnableOption // enabledGames;

in
{
  options = {
    axiom.admin.applications = lib.mkOption {
      type = lib.types.submodule {
        options = lib.mapAttrs (name: _: {
          enable = lib.mkEnableOption "${name} application";
        }) appsWithEnableOption;
      };
      default = { };
    };
    axiom.admin.games = lib.mkOption {
      type = lib.types.submodule {
        options = lib.mapAttrs (name: _: {
          enable = lib.mkEnableOption "${name} game";
        }) games;
      };
      default = { };
    };
  };

  config = {
    # Install available GUI applications
    # Only include applications that define a `package` attribute.
    home.packages = lib.attrValues (
      lib.mapAttrs (_: app: app.package) (lib.filterAttrs (_: app: app ? package) allActiveApps)
    );

    # Create desktop entries for applications
    xdg.desktopEntries = lib.mapAttrs (name: app: {
      name = lib.strings.toUpper (lib.substring 0 1 name) + lib.substring 1 (-1) name;
      comment = app.comment;
      exec = app.exec;
      icon = app.icon;
      categories = app.categories;
      terminal = app.isTui or false;
      startupNotify = true;
    }) allActiveApps;

    # Create rofi-specific desktop entries (RofiCustom category)
    xdg.dataFile =
      lib.mapAttrs' (name: app: {
        name = "applications/rofi-${name}.desktop";
        value = {
          text = ''
            [Desktop Entry]
            Version=1.0
            Type=Application
            Name=${name}
            Comment=${app.comment}
            Exec=${if app.isTui or false then "kitty -e ${app.exec}" else app.exec}
            Icon=${app.icon}
            Categories=${lib.concatStringsSep ";" app.categories};RofiCustom;
            Terminal=false
            StartupNotify=true
          '';
        };
      }) (lib.filterAttrs (_: app: !(app.hideFromRofi or false)) allActiveApps)
      // lib.mapAttrs' (name: app: {
        name = "applications/launcher-${name}.desktop";
        value = {
          text = ''
            [Desktop Entry]
            Version=1.0
            Type=Application
            Name=${name}
            Comment=${app.comment}
            Exec=${app.exec}
            Icon=${app.icon}
            Categories=${lib.concatStringsSep ";" app.categories};LauncherCustom;
            Terminal=${if app.isTui or false then "true" else "false"}
            StartupNotify=true
          '';
        };
      }) allActiveApps;
  };
}
