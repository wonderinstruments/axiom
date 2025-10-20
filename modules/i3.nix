{ config, pkgs, ... }:

{
  services.xserver.windowManager.i3.configFile = pkgs.writeText "i3-config" ''
    # i3 config file (v4)

    # Set mod key (Mod1=<Alt>, Mod4=<Super>)
    set $mod Mod4

    # Start XDG autostart .desktop files using dex
    exec --no-startup-id dex --autostart --environment i3

    # Use Mouse+$mod to drag floating windows
    floating_modifier $mod

    # Move tiling windows via drag & drop by left-clicking into the title bar
    tiling_drag modifier titlebar

    # Start polybar instead of i3bar - disable i3bar completely
    # bar {
    #     status_command i3status
    # }

    # Start polybar on startup
    exec_always --no-startup-id systemctl --user restart polybar
  '';
}
