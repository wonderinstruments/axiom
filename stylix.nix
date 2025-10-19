{ pkgs, stylix, ... }:
{
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/thems/gruvbox-dark-hard.yaml";
    fonts = {
      monospace = {
        package = pkgs.atkinson-hyperlegible-mono;
        name = "Atkinson Hyperlegible Mono";
      };
    };
  };
}
