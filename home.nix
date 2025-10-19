{
  config,
  pkgs,
  lib,
  kickstart,
  stylix,
  ...
}:
{
  home.stateVersion = "25.05";

  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = "Mod4";
      terminal = "kitty";
      keybindings = {
        "Mod4+Return" = "exec kitty";
      };
    };
  };
  programs.kitty.enable = true;
  programs.bat.enable = true;
  programs.rofi.enable = true;

  programs.command-not-found.enable = false;
  programs.fish = {
    enable = false;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
      zoxide init fish | source
    '';
    functions.__fish_command_not_found_handler = {
      onEvent = "fish_command_not_found";
      body = ''
        	set -l cmd $argv[1]
                echo "'$cmd' not found"
        	true
      '';
    };
  };
}
