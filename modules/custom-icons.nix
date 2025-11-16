{ config, pkgs, ... }:

{
  # Install custom application icons
  xdg.dataFile = {
    "icons/hicolor/128x128/apps/tuxtype.png".source = ../icons/tuxtype.png;
    "icons/hicolor/128x128/apps/freeplane.png".source = ../icons/freeplane.png;
    "icons/hicolor/scalable/apps/kwave.svg".source = ../icons/kwave.svg;
    "icons/hicolor/128x128/apps/shotcut.png".source = ../icons/shotcut.png;
    "icons/hicolor/128x128/apps/spotify.png".source = ../icons/spotify.png;
    "icons/hicolor/128x128/apps/warp.png".source = ../icons/warp.png;
    "icons/hicolor/128x128/apps/endless-sky.png".source = ../icons/endless-sky.png;
  };

  # Update icon cache after installation
  home.activation.updateIconCache = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if command -v gtk-update-icon-cache &> /dev/null; then
      $DRY_RUN_CMD ${pkgs.gtk3}/bin/gtk-update-icon-cache -f -t $HOME/.local/share/icons/hicolor
    fi
  '';
}
