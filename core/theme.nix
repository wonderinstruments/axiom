{ pkgs, ... }:
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
}
