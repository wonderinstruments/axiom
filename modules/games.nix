{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.admin.games;

  games = {
    freeciv = {
      package = pkgs.freeciv;
      exec = "freeciv-gtk3.22";
      icon = "freeciv";
      comment = "Freeciv";
      categories = [
        "Game"
      ];
    };
    widelands = {
      package = pkgs.widelands;
      exec = "widelands";
      icon = "widelands";
      comment = "Widelands";
      categories = [
        "Game"
      ];
    };
    the-powder-toy = {
      package = pkgs.the-powder-toy;
      exec = "powder";
      icon = "the-powder-toy";
      comment = "The Powder Toy";
      categories = [
        "Game"
      ];
    };
    luanti = {
      package = pkgs.luanti;
      exec = "luanti";
      icon = "luanti";
      comment = "Luanti";
      categories = [
        "Game"
      ];
    };
    zeroad = {
      package = pkgs.zeroad;
      exec = "zeroad";
      icon = "zeroad";
      comment = "0 A.D.";
      categories = [
        "Game"
      ];
    };
    openttd = {
      package = pkgs.openttd;
      exec = "openttd";
      icon = "openttd";
      comment = "OpenTTD";
      categories = [
        "Game"
      ];
    };
    katomic = {
      package = pkgs.kdePackages.katomic;
      exec = "katomic";
      icon = "katomic";
      comment = "KAtomic";
      categories = [
        "Game"
      ];
    };
    mindustry = {
      package = pkgs.mindustry;
      exec = "mindustry";
      icon = "mindustry";
      comment = "Mindustry";
      categories = [
        "Game"
      ];
    };
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
