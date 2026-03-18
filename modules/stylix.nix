{
  lib,
  config,
  pkgs,
  stylix,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.axiom.theme;
in
{
  options.axiom.theme = {
    colors = mkOption {
      type = types.enum [
        "rose-pine-moon"
        "everforest"
        "moonlight"
        "spaceduck"
        "woodland"
        "sandcastle"
        "caroline"
        "ascendancy"
        "selenized-dark"
        "tokyo-night-storm"
        "zenbones"
        "eris"
        "blueforest"
        "aztec"
        "zenburn"
      ];
      default = "tokyo-night-storm";
      description = "System theme colors";
    };
    windows.shadow.size = mkOption {
      type = types.int;
      default = 50;
      description = "Shadow size for window manager";
    };
    windows.gap.size = mkOption {
      type = types.int;
      default = 40;
      description = "Gap size for window manager";
    };
  };
  config = {
    stylix = {
      enable = true;
      targets.firefox.enable = false;
      targets.kde.enable = false;

      # Placeholder image required by stylix (actual wallpaper set by fractal-wallpaper module)
      image = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-simple-dark-gray.png";
        sha256 = "sha256-PK1YzLenPE8gdUpTdWFxS8JAEGdIoKmr0kCZrviMB4A=";
      };

      base16Scheme = "${pkgs.base16-schemes}/share/themes/${cfg.colors}.yaml";

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

    # Write colors to file for axiom Python library
    home.activation.writeAxiomColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${config.home.homeDirectory}/.config/axiom
      run cat > ${config.home.homeDirectory}/.config/axiom/colors << 'EOF'
      ${builtins.toJSON {
        base00 = config.lib.stylix.colors.base00;
        base01 = config.lib.stylix.colors.base01;
        base02 = config.lib.stylix.colors.base02;
        base03 = config.lib.stylix.colors.base03;
        base04 = config.lib.stylix.colors.base04;
        base05 = config.lib.stylix.colors.base05;
        base06 = config.lib.stylix.colors.base06;
        base07 = config.lib.stylix.colors.base07;
        base08 = config.lib.stylix.colors.base08;
        base09 = config.lib.stylix.colors.base09;
        base0A = config.lib.stylix.colors.base0A;
        base0B = config.lib.stylix.colors.base0B;
        base0C = config.lib.stylix.colors.base0C;
        base0D = config.lib.stylix.colors.base0D;
        base0E = config.lib.stylix.colors.base0E;
        base0F = config.lib.stylix.colors.base0F;
      }}
      EOF
    '';
  };
}
