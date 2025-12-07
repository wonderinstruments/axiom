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
  ];

  # Nix configuration
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Base system packages
  environment.systemPackages = with pkgs; [
    axiom-rebuild
  ];

  # Guide LLM service
  # TODO: Make user configurable (currently hardcoded)
  services.guide = {
    enable = true;
    user = "edmund";
    group = "users";
    package = pkgs.guide;
    launcherPackage = pkgs.guide-llama-launcher;
  };

  # Do not change - tracks NixOS version for state compatibility
  system.stateVersion = "25.05";
}
