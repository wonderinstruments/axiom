{ pkgs, stylix, ... }:
{
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";
    fonts = {
      monospace = {
        package = pkgs.atkinson-hyperlegible-mono;
        name = "Atkinson Hyperlegible Mono";
      };
      sansSerif = {
        package = pkgs.atkinson-hyperlegible-next;
        name = "Atkinson Hyperlegible Next";
      };
    };
  };
}
