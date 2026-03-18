{ pkgs, lib, ... }:
{
  fonts = {
    packages =
      with pkgs;
      [
        atkinson-hyperlegible-next
        atkinson-hyperlegible-mono
      ]
      ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
  };

  # Disable NixOS-level stylix auto-import since we configure it in home-manager
  stylix.homeManagerIntegration.autoImport = false;
}
