{ pkgs, ... }:
{
  programs.command-not-found.enable = false;
  programs.fish = {
    enable = true;
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
