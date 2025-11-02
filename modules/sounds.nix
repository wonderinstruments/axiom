{ config, pkgs, ... }:
{
  home.packages = [
    pkgs.libcanberra
    pkgs.libcanberra-gtk3
  ];

  # Install sound theme files
  xdg.dataFile."sounds/WonderTheme/index.theme".text = ''
    [Sound Theme]
    Name=WonderTheme
    Comment=Wonder Instruments custom system sound theme
    Directories=stereo
    Inherits=freedesktop

    [stereo]
    OutputProfile=stereo
  '';
  
  xdg.dataFile."sounds/WonderTheme/stereo/trash-empty.ogg".source = ../sounds/trash.ogg;
}
