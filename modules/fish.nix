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
    programs.eza.enable = true;
    programs.eza.icons = "always";
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
                                set fish_greeting # Disable greeting
                                zoxide init fish | source
        			export LESS="-R -Ps(-- press 'q' to quit, '/' to search, arrows to scroll, 'h' for help --)"
                        	bat ~/WELCOME.md
                        	
                        	# Guide LLM integration - type ?your question
                        	function ?
                        	  if test (count $argv) -eq 0
                        	    echo "Usage: ? your question here"
                        	    return 1
                        	  end
                        	  
                        	  set -l prompt (string join " " $argv)
                        	  history --null --max=200 | guide --from-fish --nul-history -- "$prompt"
                        	end
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
        # Always alias ls to eza
        ls = {
          wraps = "ls";
          body = ''
            	    eza
            	  '';
        };
      }
      // lib.optionalAttrs cfg.autoEza.enable {
        # Override cd to run eza after changing directory
        cd = {
          wraps = "cd";
          body = ''
            builtin cd $argv
            and eza
          '';
        };
        # Override z to run eza after changing directory
        z = {
          wraps = "z";
          body = ''
            __zoxide_z $argv
            and eza
          '';
        };
      };
      shellAliases = lib.optionalAttrs cfg.rmToTrash.enable {
        rm = "trash";
      };
    };
  };
}
