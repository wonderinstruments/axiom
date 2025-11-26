{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Install navi cheat sheets to ~/.local/share/navi/cheats/
  xdg.dataFile."navi/cheats/axiom.cheat" = {
    source = ../navi-cheats/axiom.cheat;
  };
}
