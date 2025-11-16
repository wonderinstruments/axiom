{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.admin.games;

  # Map of games to Nix packages
  games = {
    endless-sky = {
      package = pkgs.endless-sky;
      exec = "endless-sky";
      icon = "endless-sky";
      comment = "Endless Sky";
      categories = [
        "Game"
      ];
    };
  };

  # Filter enabled applications
  enabledApps = lib.filterAttrs (name: _: cfg.${name}.enable) games;

in
{
  options = {
    axiom.admin.games = lib.mkOption {
      type = lib.types.submodule {
        options = lib.mapAttrs (name: _: {
          enable = lib.mkEnableOption "${name} game";
        }) games;
      };
      default = { };
    };
  };
  config = lib.mkMerge [
    {
      # Install enabled admin applications
      home.packages = lib.attrValues (lib.mapAttrs (_: app: app.package) enabledApps);

      # Create desktop entries for enabled applications
      xdg.desktopEntries = lib.mapAttrs (name: app: {
        name = lib.strings.toUpper (lib.substring 0 1 name) + lib.substring 1 (-1) name;
        comment = app.comment;
        exec = app.exec;
        icon = app.icon;
        categories = app.categories;
        terminal = false;
        startupNotify = true;
      }) enabledApps;

      # Create rofi-specific desktop entries (RofiCustom category)
      xdg.dataFile = lib.mapAttrs' (name: app: {
        name = "applications/rofi-${name}.desktop";
        value = {
          text = ''
            [Desktop Entry]
            Version=1.0
            Type=Application
            Name=${name}
            Comment=${app.comment}
            Exec=${app.exec}
            Icon=${app.icon}
            Categories=${lib.concatStringsSep ";" app.categories};RofiCustom;
            Terminal=false
            StartupNotify=true
          '';
        };
      }) enabledApps;
    }
  ];
}
