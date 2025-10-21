{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
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
    trashy
    ripgrep
    tldr
  ];

  programs.fish.enable = true;
  documentation.man.generateCaches = false;

  programs.less.enable = true;

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    shortcut = "a";
    terminal = "screen-256color";
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      yank
    ];
  };

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
