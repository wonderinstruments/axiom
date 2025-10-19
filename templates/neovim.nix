{ ... }:
{
  axiom.neovim = {
    # Set true once if you want to nuke ~/.config/nvim and re-seed on next switch
    resetOnNextSwitch = false;

    extraLua = ''
      vim.o.number = true
      vim.o.relativenumber = true
      vim.o.updatetime = 200
    '';
  };
}
