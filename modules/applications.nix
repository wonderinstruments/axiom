{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

let
  # Map of Ansible applications to Nix packages where available
  nixApplications = {
    # Gaming
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

    # Text Editors & Writing
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

    # Information & Education
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

    # Edutainment
    tuxtype = {
      package = pkgs.tuxtype;
      exec = "tuxtype";
      icon = "tuxtype";
      comment = "Educational Typing Tutor Game";
      categories = [
        "Education"
        "Game"
      ];
    };

    # Creativity
    shotcut = {
      package = pkgs.shotcut;
      exec = "shotcut";
      icon = "shotcut";
      comment = "Video editor";
      categories = [
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
        "Education"
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
      categories = [ ];
    };
  };

in
{
  # Install available GUI applications
  home.packages = lib.attrValues (lib.mapAttrs (_: app: app.package) nixApplications);

  # Create desktop entries for applications
  xdg.desktopEntries = lib.mapAttrs (name: app: {
    name = lib.strings.toUpper (lib.substring 0 1 name) + lib.substring 1 (-1) name;
    comment = app.comment;
    exec = app.exec;
    icon = app.icon;
    categories = app.categories;
    terminal = false;
    startupNotify = true;
  }) nixApplications;

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
  }) nixApplications;
}
