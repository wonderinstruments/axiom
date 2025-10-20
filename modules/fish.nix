{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.terminal;
in
{
  options = {
    axiom.terminal = {
      rmToTrash = {
        enable = lib.mkEnableOption "Alias rm to trash for safety";
      };
      autoEza = {
        enable = lib.mkEnableOption "Automatically run eza after cd/z commands";
      };
    };
  };

  config = {
    programs.command-not-found.enable = false;
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # Disable greeting
        zoxide init fish | source
      '';
      functions = {
        __fish_command_not_found_handler = {
          onEvent = "fish_command_not_found";
          body = ''
            	set -l cmd $argv[1]
                    echo "'$cmd' not found"
            	true
          '';
        };
      }
      // lib.optionalAttrs cfg.autoEza.enable {
        # Override cd to run eza after changing directory
        cd = {
          wraps = "cd";
          body = ''
            builtin cd $argv
            and eza --icons=always
          '';
        };
      };
      shellAliases = lib.optionalAttrs cfg.rmToTrash.enable {
        rm = "trash";
      };
    };
  };
}
