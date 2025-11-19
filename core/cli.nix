{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    lazygit
    gh
    tmux
    eza
    ranger
    fzf
    nixfmt-rfc-style
    nixfmt-tree
    starship
    kitty
    bat
    rofi
    wmctrl
    trashy
    ripgrep
    tldr
    fd
    ffmpeg
  ];

  programs.fish.enable = true;
  documentation.man.generateCaches = false;

  programs.less.enable = true;

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.git = {
    enable = true;
    config = {
      push.autoSetupRemote = true;
      init.defaultBranch = "trunk";
    };
  };

  programs.starship.enable = true;
}
