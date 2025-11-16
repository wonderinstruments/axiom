{ config, lib, ... }:
let
  inherit (config.lib.stylix) colors;
in
{
  home.file.".config/micro/colorschemes/stylix.micro".text = ''
    # Stylix-generated colorscheme for micro
    color-link default "${colors.base05},${colors.base00}"
    color-link color-column "${colors.base01}"
    color-link comment "${colors.base03}"
    color-link constant "${colors.base09}"
    color-link constant.specialChar "${colors.base0F}"
    color-link constant.string "${colors.base0B}"
    color-link current-line-number "${colors.base04},${colors.base01}"
    color-link cursor-line "${colors.base01}"
    color-link divider "${colors.base01}"
    color-link error "${colors.base08}"
    color-link diff-added "${colors.base0B}"
    color-link diff-modified "${colors.base0A}"
    color-link diff-deleted "${colors.base08}"
    color-link gutter-error "${colors.base08}"
    color-link gutter-warning "${colors.base0A}"
    color-link hlsearch "${colors.base00},${colors.base0A}"
    color-link identifier "${colors.base08}"
    color-link identifier.class "${colors.base0A}"
    color-link identifier.var "${colors.base0D}"
    color-link indent-char "${colors.base02}"
    color-link line-number "${colors.base04},${colors.base01}"
    color-link preproc "${colors.base0A}"
    color-link special "${colors.base0F}"
    color-link statement "${colors.base0E}"
    color-link statusline "${colors.base04},${colors.base01}"
    color-link symbol "${colors.base05}"
    color-link symbol.brackets "${colors.base05}"
    color-link symbol.operator "${colors.base05}"
    color-link symbol.tag "${colors.base0A}"
    color-link tabbar "${colors.base05},${colors.base02}"
    color-link todo "${colors.base0D}"
    color-link type "${colors.base0A}"
    color-link type.keyword "${colors.base0E}"
    color-link underlined "${colors.base0D}"
    color-link match-brace "${colors.base00},${colors.base0A}"
    color-link tab-error "${colors.base08}"
    color-link trailingws "${colors.base08}"
  '';

  programs.micro = {
    enable = true;
    settings = {
      colorscheme = lib.mkForce "stylix";
      syntax = true;
    };
  };
}
