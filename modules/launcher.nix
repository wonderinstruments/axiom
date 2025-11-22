{
  config,
  lib,
  pkgs,
  launcher,
  ...
}:

{
  # Install the launcher package from the flake
  home.packages = [ launcher.packages.${pkgs.system}.default ];

  # Create a desktop entry for the launcher
  xdg.desktopEntries.launcher = {
    name = "Launcher";
    comment = "TUI Application Launcher";
    exec = "kitty -e launcher";
    icon = "preferences-system";
    categories = [ "System" "Utility" ];
    terminal = false;
    startupNotify = true;
  };
}
