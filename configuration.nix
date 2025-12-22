# Axiom NixOS Configuration
# Core system modules are in ./core/
# Per-user home-manager modules are in ./modules/

{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./core/boot.nix
    ./core/hardware.nix
    ./core/cli.nix
    ./core/theme.nix
    ./core/python.nix
    ./core/mime.nix
    ./core/users.nix
    ./core/system.nix
    ./core/desktop.nix
    ./core/guide.nix
    ./core/axiom-connect.nix
  ];

  # Nix configuration
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  # Base system packages
  environment.systemPackages = with pkgs; [
    axiom-rebuild
  ];

  # Do not change
  system.stateVersion = "25.05";
}
