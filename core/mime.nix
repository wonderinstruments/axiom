{
  lib,
  pkgs,
  config,
  ...
}:
{
  # Enable xdg-desktop-portal
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [ "gtk" ];
  };

  # Set kitty as default terminal emulator
  xdg.terminal-exec = {
    enable = true;
    settings = {
      default = [ "kitty.desktop" ];
    };
  };

  # Set up xdg-open defaults
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    # PDFs and ebooks
    "application/pdf" = "zathura.desktop";
    "application/epub+zip" = "zathura.desktop";

    # Images - vimiv for raster, inkscape for vector editing
    "image/png" = "vimiv.desktop";
    "image/jpeg" = "vimiv.desktop";
    "image/gif" = "vimiv.desktop";
    "image/webp" = "vimiv.desktop";
    "image/bmp" = "vimiv.desktop";
    "image/tiff" = "vimiv.desktop";
    "image/svg+xml" = "inkscape.desktop";

    # Audio - kwave for editing, rosegarden for MIDI
    "audio/mpeg" = "kwave.desktop";
    "audio/ogg" = "kwave.desktop";
    "audio/wav" = "kwave.desktop";
    "audio/flac" = "kwave.desktop";
    "audio/x-wav" = "kwave.desktop";
    "audio/mp4" = "kwave.desktop";
    "audio/midi" = "rosegarden.desktop";
    "audio/x-midi" = "rosegarden.desktop";

    # Video - vlc for playback
    "video/mp4" = "vlc.desktop";
    "video/webm" = "vlc.desktop";
    "video/x-matroska" = "vlc.desktop";
    "video/quicktime" = "vlc.desktop";
    "video/x-msvideo" = "vlc.desktop";

    # Text and documents
    "text/plain" = "nvim.desktop";
    "text/markdown" = "ghostwriter.desktop";
    "application/json" = "fx.desktop";

    # Python files - open with Thonny
    "text/x-python" = "thonny.desktop";
    "text/x-python3" = "thonny.desktop";

    # Spreadsheets and data
    "text/csv" = "visidata.desktop";
    "application/vnd.ms-excel" = "visidata.desktop";
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "visidata.desktop";

    # Mind maps
    "application/x-freeplane" = "freeplane.desktop";

    # Anki
    "application/x-apkg" = "anki.desktop";
    "application/x-anki" = "anki.desktop";

    # Directories
    "inode/directory" = "xplr.desktop";
  };
}
