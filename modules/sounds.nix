{ config, pkgs, ... }:
{
  home.packages = [
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

  xdg.dataFile."sounds/WonderTheme/stereo/trash.ogg".source = ../sounds/trash.ogg;
  xdg.dataFile."sounds/WonderTheme/stereo/oops.wav".source = ../sounds/oops.wav;

  # Configure the system to use the sound theme
  dconf.settings = {
    "org/gnome/desktop/sound" = {
      theme-name = "WonderTheme";
      event-sounds = true;
      input-feedback-sounds = false;
    };
  };
}
