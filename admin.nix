{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    warp-terminal
    spotify
    obsidian
    slack
    discord
  ];
  programs.chromium.enable = true;
}
