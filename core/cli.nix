{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    gh
    tmux
    eza
    fzf
    nixfmt-rfc-style
    nixfmt-tree
    starship
    kitty
    bat
    rofi
    wmctrl
    xorg.xprop
    jq
    yq
    trashy
    ripgrep
    tldr
    fd
    ffmpeg
    sox
    fx
    # play
    wthrr
    rip2
    unzip
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
