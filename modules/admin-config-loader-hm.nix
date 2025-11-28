# Admin Configuration Loader (Home Manager module)
#
# This module reads admin configuration from /etc/axiom/admin.toml
# and maps the values to the appropriate axiom.admin.* options.
#
# This file can only be modified by root, providing a security boundary
# for options like which applications/games are available.

{ lib, config, pkgs, ... }:

let
  # Path to admin config file
  adminConfigPath = /etc/axiom/admin.toml;
  
  # Read and parse the TOML file if it exists, otherwise use empty attrset
  adminConfig = 
    if builtins.pathExists adminConfigPath
    then builtins.fromTOML (builtins.readFile adminConfigPath)
    else {};
  
  # Helper function to safely get nested values with defaults
  get = path: default: lib.attrByPath path default adminConfig;
  
  # Helper for boolean values
  getBool = path: default: get path default;

in
{
  config = {
    # =========================================================================
    # Web browser settings
    # =========================================================================
    axiom.admin.web.firefox.enable = getBool ["web" "firefox" "enable"] false;
    axiom.admin.web.chromium.enable = getBool ["web" "chromium" "enable"] false;
    
    # =========================================================================
    # Games settings
    # =========================================================================
    axiom.admin.games = {
      endless-sky.enable = getBool ["games" "endless-sky" "enable"] false;
      widelands.enable = getBool ["games" "widelands" "enable"] false;
      freeciv.enable = getBool ["games" "freeciv" "enable"] false;
      the-powder-toy.enable = getBool ["games" "the-powder-toy" "enable"] false;
      zeroad.enable = getBool ["games" "zeroad" "enable"] false;
      openttd.enable = getBool ["games" "openttd" "enable"] false;
      katomic.enable = getBool ["games" "katomic" "enable"] false;
      mindustry.enable = getBool ["games" "mindustry" "enable"] false;
      luanti.enable = getBool ["games" "luanti" "enable"] false;
      pingus.enable = getBool ["games" "pingus" "enable"] false;
      tuxtype.enable = getBool ["games" "tuxtype" "enable"] false;
    };
    
    # =========================================================================
    # Applications settings
    # =========================================================================
    axiom.admin.applications = {
      xiphos.enable = getBool ["applications" "xiphos" "enable"] false;
      warp-terminal.enable = getBool ["applications" "warp-terminal" "enable"] false;
      spotify.enable = getBool ["applications" "spotify" "enable"] false;
      obsidian.enable = getBool ["applications" "obsidian" "enable"] false;
      slack.enable = getBool ["applications" "slack" "enable"] false;
      discord.enable = getBool ["applications" "discord" "enable"] false;
    };
  };
}
