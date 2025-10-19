{
  pkgs,
  lib,
  kickstart,
  ...
}:
{
  imports = [ ./modules/my-neovim.nix ];

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
  myNeovim = {
    enable = true;

    # Set true once if you want to nuke ~/.config/nvim and re-seed on next switch
    resetOnNextSwitch = false;

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

    extraPackages = with pkgs; [
      ripgrep
      fd
      lua-language-server
    ];
  };
}
