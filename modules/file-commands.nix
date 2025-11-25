{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.fileCommands;

  # Wrapper for xplr that handles file:// URLs from exo-open
  xplrOpen = pkgs.writeShellScriptBin "xplr-open" ''
    path="$1"
    # Strip file:// prefix if present
    path="''${path#file://}"
    # URL decode (handle %20 etc)
    path=$(printf '%b' "''${path//%/\\x}")
    exec ${pkgs.xplr}/bin/xplr "$path"
  '';

  # Semantic file opener script - dispatches based on file type
  viewScript = pkgs.writeShellScriptBin "view" ''
    if [ $# -eq 0 ]; then
      echo "Usage: view <file>"
      echo "View files in read-only mode based on their type"
      exit 1
    fi

    file="$1"
    if [ ! -e "$file" ]; then
      echo "File not found: $file"
      exit 1
    fi

    mime=$(${pkgs.file}/bin/file --mime-type -b "$file")

    case "$mime" in
      # Images
      image/*)
        ${pkgs.vimiv-qt}/bin/vimiv "$file"
        ;;
      # PDFs and documents
      application/pdf)
        ${pkgs.zathura}/bin/zathura "$file"
        ;;
      application/epub*)
        ${pkgs.zathura}/bin/zathura "$file"
        ;;
      # JSON files
      application/json)
        ${pkgs.fx}/bin/fx "$file"
        ;;
      # CSV and tabular data
      text/csv|application/vnd.ms-excel)
        ${pkgs.visidata}/bin/vd "$file"
        ;;
      # Text files - use bat for syntax highlighting
      text/*|application/xml|application/javascript)
        ${pkgs.bat}/bin/bat --paging=always "$file"
        ;;
      # Fallback
      *)
        echo "Don't know how to view $mime files"
        echo "Try: open $file"
        exit 1
        ;;
    esac
  '';

  # Play media files
  # Show documents (PDFs, ebooks, text)
  showScript = pkgs.writeShellScriptBin "show" ''
    if [ $# -eq 0 ]; then
      echo "Usage: read <file>"
      echo "Read documents like PDFs, ebooks, and text files"
      exit 1
    fi

    file="$1"
    if [ ! -e "$file" ]; then
      echo "File not found: $file"
      exit 1
    fi

    mime=$(${pkgs.file}/bin/file --mime-type -b "$file")

    case "$mime" in
      # PDFs and ebooks
      application/pdf|application/epub*)
        ${pkgs.zathura}/bin/zathura "$file"
        ;;
      # JSON files
      application/json)
        ${pkgs.fx}/bin/fx "$file"
        ;;
      # Text files
      text/*)
        ${pkgs.bat}/bin/bat --paging=always "$file"
        ;;
      # Fallback to view
      *)
        ${viewScript}/bin/view "$file"
        ;;
    esac
  '';

  playScript = pkgs.writeShellScriptBin "play" ''
    if [ $# -eq 0 ]; then
      echo "Usage: play <file>"
      echo "Play audio or video files"
      exit 1
    fi

    file="$1"
    if [ ! -e "$file" ]; then
      echo "File not found: $file"
      exit 1
    fi

    mime=$(${pkgs.file}/bin/file --mime-type -b "$file")

    # Check file extension for MIDI (mime detection is unreliable)
    ext="''${file##*.}"
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    case "$mime" in
      # MIDI files - use rosegarden for playback
      audio/midi|audio/x-midi)
        ${pkgs.rosegarden}/bin/rosegarden "$file"
        ;;
      # Audio - use sox for quick terminal playback
      audio/*)
        ${pkgs.sox}/bin/play "$file"
        ;;
      # Video - use vlc
      video/*)
        ${pkgs.vlc}/bin/vlc --play-and-exit "$file"
        ;;
      # Fallback - check extension for MIDI
      *)
        if [ "$ext_lower" = "mid" ] || [ "$ext_lower" = "midi" ]; then
          ${pkgs.rosegarden}/bin/rosegarden "$file"
        else
          echo "Don't know how to play $mime files"
          exit 1
        fi
        ;;
    esac
  '';

in
{
  options.axiom.fileCommands = {
    enable = lib.mkEnableOption "semantic file commands (view, play, show)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      viewScript
      showScript
      playScript
    ];

    # Add 'open' alias for xdg-open
    programs.fish.shellAliases = {
      open = "xdg-open";
    };

    # Configure XFCE to use xplr as file manager (via kitty)
    xdg.configFile."xfce4/helpers.rc".text = ''
      FileManager=xplr
    '';

    # XFCE helper definition for xplr
    xdg.dataFile."xfce4/helpers/xplr.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Icon=xplr
      Type=X-XFCE-Helper
      Name=xplr
      X-XFCE-Binaries=xplr-open;
      X-XFCE-Category=FileManager
      X-XFCE-Commands=kitty -e xplr;
      X-XFCE-CommandsWithParameter=kitty -e ${xplrOpen}/bin/xplr-open "%s";
    '';
  };
}
