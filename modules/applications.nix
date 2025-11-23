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
        "Games"
      ];
    };
    widelands = {
      package = pkgs.widelands;
      exec = "widelands";
      icon = "widelands";
      comment = "Widelands";
      categories = [
        "Games"
      ];
    };
    the-powder-toy = {
      package = pkgs.the-powder-toy;
      exec = "powder";
      icon = "the-powder-toy";
      comment = "The Powder Toy";
      categories = [
        "Games"
      ];
    };
    luanti = {
      package = pkgs.luanti;
      exec = "luanti";
      icon = "luanti";
      comment = "Luanti";
      categories = [
        "Games"
      ];
    };
    zeroad = {
      package = pkgs.zeroad;
      exec = "zeroad";
      icon = "zeroad";
      comment = "0 A.D.";
      categories = [
        "Games"
      ];
    };
    openttd = {
      package = pkgs.openttd;
      exec = "openttd";
      icon = "openttd";
      comment = "OpenTTD";
      categories = [
        "Games"
      ];
    };
    katomic = {
      package = pkgs.kdePackages.katomic;
      exec = "katomic";
      icon = "katomic";
      comment = "KAtomic";
      categories = [
        "Games"
      ];
    };
    mindustry = {
      package = pkgs.mindustry;
      exec = "mindustry";
      icon = "mindustry";
      comment = "Mindustry";
      categories = [
        "Games"
      ];
    };
    endless-sky = {
      package = pkgs.endless-sky;
      exec = "endless-sky";
      icon = "endless-sky";
      comment = "Endless Sky";
      categories = [
        "Games"
      ];
    };
    pingus = {
      package = pkgs.pingus;
      exec = "pingus";
      icon = "pingus";
      comment = "Lemmings-like puzzle game";
      categories = [
        "Games"
        "ArcadeGame"
      ];
    };
    tuxtype = {
      package = pkgs.tuxtype;
      exec = "tuxtype";
      icon = "tuxtype";
      comment = "Educational Typing Tutor Game";
      categories = [
        "Games"
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
        "Programming"
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
        "Misc"
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
        "Thinking"
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
        "Communication"
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
        "Communication"
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
        "File Openers"
        "Office"
      ];
    };
    zathura = {
      package = pkgs.zathura;
      exec = "zathura";
      icon = "zathura";
      comment = "PDF Reader";
      categories = [
        "File Openers"
        "Office"
      ];
    };
    ghostwriter = {
      package = pkgs.kdePackages.ghostwriter;
      exec = "ghostwriter";
      icon = "ghostwriter";
      comment = "Markdown Editor";
      categories = [
        "Thinking"
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
        "Thinking"
      ];
    };

    # Information & Education
    xiphos = {
      package = pkgs.xiphos;
      exec = "xiphos";
      icon = "xiphos";
      comment = "Bible Study";
      categories = [
        "World Knowledge"
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
        "Thinking"
      ];
    };
    stellarium = {
      package = pkgs.stellarium;
      exec = "stellarium";
      icon = "stellarium";
      comment = "Desktop Planetarium";
      categories = [
        "World Knowledge"
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
        "World Knowledge"
        "Learning"
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
        "World Knowledge"
        "Learning"
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
        "World Knowledge"
        "Learning"
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
        "Art"
        "Graphics"
      ];
    };
    shotcut = {
      package = pkgs.shotcut;
      exec = "shotcut";
      icon = "shotcut";
      comment = "Video editor";
      categories = [
        "Video Editing"
        "AudioVideo"
        "Video"
      ];
    };
    kwave = {
      package = pkgs-unstable.kdePackages.kwave;
      exec = "kwave";
      icon = "kwave";
      comment = "Audio Editor";
      categories = [
        "File Openers"
        "AudioVideo"
        "Audio"
      ];
    };
    rosegarden = {
      package = pkgs.rosegarden;
      exec = "rosegarden";
      icon = "rosegarden";
      comment = "Audio composer";
      categories = [
        "Music"
        "AudioVideo"
        "Audio"
      ];
    };
    easyeffects = {
      package = pkgs.easyeffects;
      exec = "easyeffects";
      icon = "easyeffects";
      comment = "Audio Effects";
      categories = [
        "Music"
        "AudioVideo"
        "Audio"
      ];
    };
    vlc = {
      package = pkgs.vlc;
      exec = "vlc";
      icon = "vlc";
      comment = "AudioVideo Player";
      categories = [
        "File Openers"
        "AudioVideo"
      ];
    };
    helm = {
      package = pkgs.helm;
      exec = "helm";
      icon = "helm";
      comment = "Polyphonic Synthesizer";
      categories = [
        "Music"
        "AudioVideo"
        "Audio"
      ];
    };
    lmms = {
      package = pkgs.lmms;
      exec = "lmms";
      icon = "lmms";
      comment = "Digital Audio Workstation";
      categories = [
        "Music"
        "AudioVideo"
        "Audio"
        "Sequencer"
      ];
    };
    krita = {
      package = pkgs.krita;
      exec = "krita";
      icon = "krita";
      comment = "Digital Painting Application";
      categories = [
        "Art"
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
        "Art"
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
        "Programming"
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
        "Games"
      ];
      isTui = true;
    };
    xplr = {
      package = pkgs.xplr;
      exec = "xplr";
      icon = "utilities-terminal";
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
      icon = "utilities-terminal";
      comment = "Process Monitor";
      categories = [
        "System"
      ];
      isTui = true;
    };
    television = {
      package = pkgs.television;
      exec = "tv";
      icon = "utilities-terminal";
      comment = "Fuzzy Finder";
      categories = [
        "System"
      ];
      isTui = true;
    };
    broot = {
      package = pkgs.broot;
      exec = "broot";
      icon = "utilities-terminal";
      comment = "Tree based file explorer";
      categories = [
        "System"
      ];
      isTui = true;
    };
    visidata = {
      package = pkgs.visidata;
      exec = "visidata";
      icon = "utilities-terminal";
      comment = "Terminal Spreadsheet";
      categories = [
        "Data Analysis"
        "Utility"
      ];
      isTui = true;
    };
    lazygit = {
      package = pkgs.lazygit;
      exec = "lazygit";
      icon = "git";
      comment = "Git Terminal UI";
      categories = [
        "Programming"
      ];
      isTui = true;
    };
    play = {
      package = pkgs.writeShellScriptBin "play-launcher" ''
        CMD=$(echo -e "awk\ngrep\nsed\njq\nyq" | fzf --prompt="Select command: ")
        if [ -n "$CMD" ]; then
          play "$CMD"
        fi
      '';
      exec = "play-launcher";
      icon = "utilities-terminal";
      comment = "Command Practice Tool";
      categories = [
        "Learn the Terminal"
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
    home.packages = lib.attrValues (lib.mapAttrs (_: app: app.package) allActiveApps);

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
      }) allActiveApps
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
