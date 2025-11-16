{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Read all files from the icons directory
  iconsDir = ../icons;
  iconFiles = builtins.readDir iconsDir;

  # Generate xdg.dataFile entries for each icon
  iconDataFiles = lib.mapAttrs' (
    filename: type:
    let
      # Determine the icon size/type based on file extension
      extension = lib.last (lib.splitString "." filename);
      size = if extension == "svg" then "scalable" else "128x128";
      iconName = lib.removeSuffix ".${extension}" filename;
    in
    lib.nameValuePair "icons/hicolor/${size}/apps/${filename}" { source = iconsDir + "/${filename}"; }
  ) (lib.filterAttrs (name: type: type == "regular") iconFiles);
in
{
  # Install custom application icons
  xdg.dataFile = iconDataFiles;

  # Update icon cache after installation
  home.activation.updateIconCache = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if command -v gtk-update-icon-cache &> /dev/null; then
      $DRY_RUN_CMD ${pkgs.gtk3}/bin/gtk-update-icon-cache -f -t $HOME/.local/share/icons/hicolor
    fi
  '';
}
