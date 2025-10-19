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
  programs.kitty = {
    enable = true;
  };
  programs.bat.enable = true;

  stylix.targets.neovim.enable = false; # using kickstart config
  stylix.enable = true;

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

  myNeovim = {
    enable = true;

    # Appended once (with a marker) at the end of init.lua
    extraLua = ''
      -- modest defaults
      vim.o.number = true
      vim.o.relativenumber = true
      vim.o.updatetime = 200
    '';

    userFiles = {
      "keymaps.lua" = ''
        vim.keymap.set("n", "<leader>e", vim.cmd.Ex, { desc = "NetRW" })
      '';
      "after/plugin/colors.lua" = ''
        pcall(vim.cmd.colorscheme, "habamax")
      '';
    };
  };
}
