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
                        	
                        	# Helper function to play sound on success/failure
                        	function __play_sound_on_result
                        	  set -l success_sound $argv[1]
                        	  set -l command_parts $argv[2..-1]
                        	  
                        	  if eval $command_parts
                        	    canberra-gtk-play -i $success_sound 2>/dev/null &
                        	  else
                        	    canberra-gtk-play -i oops 2>/dev/null &
                        	    return 1
                        	  end
                        	end
      '';
      functions = {
        __fish_command_not_found_handler = {
          onEvent = "fish_command_not_found";
          body = ''
            	set -l cmd $argv[1]
                    canberra-gtk-play -i oops 2>/dev/null &
                    echo "'$cmd' not found"
            	true
          '';
        };
        # Always alias ls to eza with sound
        ls = {
          wraps = "ls";
          body = ''
            if eza $argv
              canberra-gtk-play -i ls 2>/dev/null &
            else
              canberra-gtk-play -i oops 2>/dev/null &
              return 1
            end
          '';
        };
        # Add sound to trash command
        trash = {
          wraps = "trash";
          body = ''
            # Only play sound if not listing or emptying
            if not contains -- $argv[1] list empty
              command trash $argv
              and canberra-gtk-play -i trash 2>/dev/null &
            else
              command trash $argv
            end
          '';
        };
        # Add sound to bat command
        bat = {
          wraps = "bat";
          body = ''
            # Check if we can open the file before playing sound
            # Run bat with --no-pager first to check if it will succeed
            if test (count $argv) -eq 0; or command bat --no-pager $argv >/dev/null 2>&1
              canberra-gtk-play -i bat 2>/dev/null &
              command bat $argv
            else
              canberra-gtk-play -i oops 2>/dev/null &
              command bat $argv
            end
          '';
        };
      }
      // lib.optionalAttrs cfg.autoEza.enable {
        # Override cd to run eza after changing directory
        cd = {
          wraps = "cd";
          body = ''
            if builtin cd $argv
              canberra-gtk-play -i cd 2>/dev/null &
              eza
            else
              canberra-gtk-play -i oops 2>/dev/null &
              return 1
            end
          '';
        };
        # Override z to run eza after changing directory
        z = {
          wraps = "z";
          body = ''
            if __zoxide_z $argv
              canberra-gtk-play -i cd 2>/dev/null &
              eza
            else
              canberra-gtk-play -i oops 2>/dev/null &
              return 1
            end
          '';
        };
      }
      // lib.optionalAttrs cfg.rmToTrash.enable {
        # Alias rm to trash (with sound)
        rm = {
          wraps = "rm";
          body = ''
            trash $argv
          '';
        };
      };
      shellAliases = { };
    };
  };
}
