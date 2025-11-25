{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.fileCommands;

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

    case "$mime" in
      # Audio - use sox for quick terminal playback
      audio/*)
        ${pkgs.sox}/bin/play "$file"
        ;;
      # Video - use vlc
      video/*)
        ${pkgs.vlc}/bin/vlc --play-and-exit "$file"
        ;;
      # Fallback
      *)
        echo "Don't know how to play $mime files"
        exit 1
        ;;
    esac
  '';

in
{
  options.axiom.fileCommands = {
    enable = lib.mkEnableOption "semantic file commands (view, play, read)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      viewScript
      playScript
    ];

    # Set up xdg-open defaults so 'open' uses sensible apps
    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = {
      # PDFs
      "application/pdf" = "zathura.desktop";

      # Images
      "image/png" = "vimiv.desktop";
      "image/jpeg" = "vimiv.desktop";
      "image/gif" = "vimiv.desktop";
      "image/webp" = "vimiv.desktop";
      "image/svg+xml" = "vimiv.desktop";
      "image/bmp" = "vimiv.desktop";
      "image/tiff" = "vimiv.desktop";

      # Audio - kwave for editing via open
      "audio/mpeg" = "kwave.desktop";
      "audio/ogg" = "kwave.desktop";
      "audio/wav" = "kwave.desktop";
      "audio/flac" = "kwave.desktop";
      "audio/x-wav" = "kwave.desktop";
      "audio/mp4" = "kwave.desktop";

      # Video - vlc for full playback/editing
      "video/mp4" = "vlc.desktop";
      "video/webm" = "vlc.desktop";
      "video/x-matroska" = "vlc.desktop";
      "video/quicktime" = "vlc.desktop";
      "video/x-msvideo" = "vlc.desktop";

      # Text - could use a GUI editor, or keep terminal-based
      "text/plain" = "nvim.desktop";
      "text/markdown" = "nvim.desktop";
      "application/json" = "fx.desktop";
    };

    # Add 'open' alias for xdg-open
    programs.fish.shellAliases = {
      open = "xdg-open";
    };
  };
}
