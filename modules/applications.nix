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
      comment = "Build civilizations from ancient times to the space age";
      categories = [
        "Game"
      ];
    };
    widelands = {
      package = pkgs.widelands;
      exec = "widelands";
      icon = "widelands";
      comment = "Build settlements and manage resources in real-time strategy";
      categories = [
        "Game"
      ];
    };
    the-powder-toy = {
      package = pkgs.the-powder-toy;
      exec = "powder";
      icon = "the-powder-toy";
      comment = "Physics sandbox where you can experiment with elements and particles";
      categories = [
        "Game"
      ];
    };
    luanti = {
      package = pkgs.luanti;
      exec = "luanti";
      icon = "luanti";
      comment = "Open-world sandbox for building and exploring with blocks";
      categories = [
        "Game"
      ];
    };
    zeroad = {
      package = pkgs.zeroad;
      exec = "zeroad";
      icon = "zeroad";
      comment = "Command ancient civilizations in historical battles and empire building";
      categories = [
        "Game"
      ];
    };
    openttd = {
      package = pkgs.openttd;
      exec = "openttd";
      icon = "openttd";
      comment = "Build and manage transportation networks with trains, planes, and ships";
      categories = [
        "Game"
      ];
    };
    katomic = {
      package = pkgs.kdePackages.katomic;
      exec = "katomic";
      icon = "katomic";
      comment = "Solve puzzles by moving atoms to build molecules";
      categories = [
        "Game"
      ];
    };
    mindustry = {
      package = pkgs.mindustry;
      exec = "mindustry";
      icon = "mindustry";
      comment = "Tower defense with factory automation and resource management";
      categories = [
        "Game"
      ];
    };
    endless-sky = {
      package = pkgs.endless-sky;
      exec = "endless-sky";
      icon = "endless-sky";
      comment = "Space trading and combat adventure across the galaxy";
      categories = [
        "Game"
      ];
    };
    pingus = {
      package = pkgs.pingus;
      exec = "pingus";
      icon = "pingus";
      comment = "Guide penguins safely through obstacles to reach their goal";
      categories = [
        "Game"
        "ArcadeGame"
      ];
    };
    tuxtype = {
      package = pkgs.tuxtype;
      exec = "tuxtype";
      icon = "tuxtype";
      comment = "Learn to type faster with fun games featuring Tux the penguin";
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
      comment = "Modern terminal for typing commands to control your computer";
      categories = [
        "Development"
        "System"
        "TerminalEmulator"
      ];
      enableOption = true;
    };
    termusic = {
      package = pkgs.termusic;
      exec = "termusic";
      icon = "termusic";
      comment = "Listen to music";
      isTui = true;
      categories = [
        "AudioVideo"
        "Audio"
      ];
    };
    spotify = {
      package = pkgs.spotify;
      exec = "spotify";
      icon = "spotify";
      comment = "Listen to millions of songs and podcasts";
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
      comment = "Organize your notes and connect ideas together";
      categories = [
        "Office"
      ];
      enableOption = true;
    };
    slack = {
      package = pkgs.slack;
      exec = "slack";
      icon = "slack";
      comment = "Chat and collaborate with your team";
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
      comment = "Talk with friends through voice, video, and text";
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
      comment = "View and browse through your photos and images";
      categories = [
        "Utility"
        "Graphics"
      ];
    };
    zathura = {
      package = pkgs.zathura;
      exec = "zathura";
      icon = "zathura";
      comment = "Read PDF documents and books";
      categories = [
        "Utility"
        "Office"
      ];
    };
    ghostwriter = {
      package = pkgs.kdePackages.ghostwriter;
      exec = "ghostwriter";
      icon = "ghostwriter";
      comment = "Write documents using Markdown formatting";
      categories = [
        "Office"
        "WordProcessor"
      ];
    };
    freeplane = {
      package = pkgs.freeplane;
      exec = "freeplane";
      icon = "freeplane";
      comment = "Create mind maps to organize your thoughts and ideas visually";
      categories = [
        "Office"
      ];
    };

    # Information & Education
    xiphos = {
      package = pkgs.xiphos;
      exec = "xiphos";
      icon = "xiphos";
      comment = "Read and study the Bible with commentary and reference tools";
      categories = [
        "Education"
      ];
      enableOption = true;
    };
    anki = {
      package = pkgs.anki;
      exec = "anki";
      icon = "anki";
      comment = "Study and memorize anything using digital flashcards";
      categories = [
        "Office"
      ];
    };
    stellarium = {
      package = pkgs.stellarium;
      exec = "stellarium";
      icon = "stellarium";
      comment = "Explore the night sky with a realistic planetarium on your computer";
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
      comment = "Travel through space in 3D and visit planets, stars, and galaxies";
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
      comment = "Explore the stars, planets, and constellations from anywhere on Earth";
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
      comment = "Explore Earth with maps, satellite views, and geographic information";
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
      comment = "Draw and edit images with simple painting tools";
      categories = [
        "Graphics"
      ];
    };
    shotcut = {
      package = pkgs.shotcut;
      exec = "shotcut";
      icon = "shotcut";
      comment = "Edit and create videos with cutting, effects, and transitions";
      categories = [
        "Video"
        "AudioVideo"
      ];
    };
    kwave = {
      package = pkgs-unstable.kdePackages.kwave;
      exec = "kwave";
      icon = "kwave";
      comment = "Edit and modify audio recordings and sound files";
      categories = [
        "Utility"
        "AudioVideo"
      ];
    };
    rosegarden = {
      package = pkgs.rosegarden;
      exec = "rosegarden";
      icon = "rosegarden";
      comment = "Compose music with MIDI and sheet music notation";
      categories = [
        "Audio"
        "AudioVideo"
      ];
    };
    easyeffects = {
      package = pkgs.easyeffects;
      exec = "easyeffects";
      icon = "easyeffects";
      comment = "Add effects like equalizers and filters to improve your audio";
      categories = [
        "Audio"
        "AudioVideo"
      ];
    };
    vlc = {
      package = pkgs.vlc;
      exec = "vlc";
      icon = "vlc";
      comment = "Play videos and music in almost any format";
      categories = [
        "Utility"
        "AudioVideo"
      ];
    };
    helm = {
      package = pkgs.helm;
      exec = "helm";
      icon = "helm";
      comment = "Create electronic music sounds with a virtual synthesizer";
      categories = [
        "Audio"
        "AudioVideo"
      ];
    };
    lmms = {
      package = pkgs.lmms;
      exec = "lmms";
      icon = "lmms";
      comment = "Create complete music tracks with instruments, beats, and effects";
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
      comment = "Paint digital artwork with professional brushes and tools";
      categories = [
        "Graphics"
        "2DGraphics"
        "RasterGraphics"
      ];
    };
    inkscape = {
      package = pkgs.inkscape;
      exec = "inkscape";
      icon = "inkscape";
      comment = "Create and edit vector graphics like logos, diagrams, and illustrations";
      categories = [
        "Graphics"
        "2DGraphics"
        "VectorGraphics"
      ];
    };
    tuxpaint = {
      package = pkgs.tuxpaint;
      exec = "tuxpaint";
      icon = "tuxpaint";
      comment = "Draw and paint with fun tools, stamps, and special effects";
      categories = [
        "Graphics"
      ];
    };
    # coding
    thonny = {
      # Package provided by modules/thonny.nix with Stylix theme
      exec = "thonny";
      icon = "thonny";
      comment = "Learn to code in Python with a beginner-friendly editor";
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
          description = "Typing test terminal user interface";
          homepage = "https://github.com/reidoboss/tttui";
          license = licenses.mit;
          platforms = platforms.linux;
        };
      };
      exec = "tttui";
      icon = "utilities-terminal";
      comment = "Test your typing speed";
      categories = [
        "Game"
      ];
      isTui = true;
    };
    gittype = {
      # No package specified: we only create desktop entries and do not
      # add anything to home.packages. Assumes gittype is available on PATH
      # (e.g. from the system profile or another module).
      exec = "gittype ${config.home.homeDirectory}/scripts";
      icon = "gittype";
      comment = "Typing challenges to improve typing speed";
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
      comment = "Manage WiFi and network connections";
      categories = [
        "Network"
        "Settings"
      ];
      isTui = true;
    };
    lazyjournal = {
      package = pkgs.lazyjournal;
      exec = "lazyjournal";
      icon = "lazyjournal";
      comment = "Explore system logs";
      categories = [
        "System"
      ];
      isTui = true;
    };
    navi = {
      package = pkgs.navi;
      exec = "navi";
      icon = "navi";
      comment = "Search for example terminal commands";
      categories = [
        "System"
      ];
      isTui = true;
    };
    glow = {
      package = pkgs.glow;
      exec = "axiom-docs";
      icon = "glow";
      comment = "Read system documentation and help files";
      categories = [
        "System"
      ];
      isTui = true;
    };
    dua = {
      package = pkgs.dua;
      exec = "dua i";
      icon = "dua";
      comment = "See which files and folders are taking up space on your computer";
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
      comment = "Browse and manage files in the terminal";
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
      comment = "See which programs are running and how much memory they use";
      categories = [
        "System"
      ];
      isTui = true;
    };
    television = {
      package = pkgs.television;
      exec = "tv";
      icon = "television";
      comment = "Quickly search and find files by typing part of their name";
      categories = [
        "System"
      ];
      isTui = true;
    };
    # broot = {
    #   package = pkgs.broot;
    #   exec = "broot";
    #   icon = "broot";
    #   comment = "Navigate files in a tree structure to see folder organization";
    #   categories = [
    #     "System"
    #   ];
    #   isTui = true;
    # };
    visidata = {
      package = pkgs.visidata;
      exec = "visidata";
      icon = "visidata";
      comment = "Work with spreadsheets and data tables in the terminal";
      categories = [
        "Office"
      ];
      isTui = true;
    };
    nvim = {
      # No package - nixvim provides nvim on PATH
      exec = "nvim";
      icon = "nvim";
      comment = "Edit text files and code with Neovim";
      categories = [
        "Utility"
        "TextEditor"
      ];
      isTui = true;
    };
    fx = {
      package = pkgs.fx;
      exec = "fx";
      icon = "utilities-terminal";
      comment = "View and explore JSON files interactively";
      categories = [
        "Utility"
        "Development"
      ];
      isTui = true;
    };
    lazygit = {
      package = pkgs.lazygit;
      exec = "lazygit";
      icon = "lazygit";
      comment = "Manage code changes and version history with Git";
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
