{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (config.lib.formats.rasi) mkLiteral;
in
{
  programs.rofi = {
    enable = true;
    terminal = "kitty";
    extraConfig = {
      # Basic modes and layout
      modi = "window,run,ssh,drun";

      # Icons and appearance
      show-icons = true;
      icon-theme = "Papirus";

      # Command settings
      ssh-client = "ssh";
      ssh-command = "{terminal} -e {ssh-client} {host} [-p {port}]";
      run-command = "{cmd}";
      run-list-command = "";
      run-shell-command = "{terminal} -e {cmd}";
      window-command = "wmctrl -i -a {window}";
      window-match-fields = "all";

      # Application launcher settings
      drun-match-fields = "name,generic,exec,categories,keywords";
      drun-categories = "RofiCustom";
      drun-show-actions = false;
      drun-display-format = "{name}";
      drun-url-launcher = "xdg-open";

      # Behavior settings
      disable-history = false;
      ignored-prefixes = "";
      sort = false;
      sorting-method = "normal";
      case-sensitive = false;
      cycle = true;
      sidebar-mode = false;
      hover-select = false;
      eh = 1;
      auto-select = false;
      parse-hosts = false;
      parse-known-hosts = true;
      combi-modi = "window,run";
      matching = "normal";
      tokenize = true;
      m = "-5";
      filter = "";
      dpi = -1;
      threads = 0;
      scroll-method = 0;

      # Display settings
      window-format = "{w}    {c}   {t}";
      click-to-exit = true;
      max-history-size = 25;
      combi-hide-mode-prefix = false;
      combi-display-format = "{mode} {text}";
      matching-negate-char = "-";
      cache-dir = "~/.cache/rofi";
      window-thumbnail = false;
      drun-use-desktop-cache = false;
      drun-reload-desktop-cache = false;
      normalize-match = false;
      steal-focus = false;
      application-fallback-icon = "";
      refilter-timeout-limit = 8192;
      xserver-i300f-workaround = false;
      pid = "/run/user/1000/rofi.pid";

      # Display names (empty to use defaults)
      display-window = "";
      display-windowcd = "";
      display-run = "";
      display-ssh = "";
      display-drun = "";
      display-combi = "";
      display-keys = "";
      display-filebrowser = "";
    };

    # Shared theme defaults (layout lives in external .rasi files)
    theme = {
      "*" = {
        padding = mkLiteral "0px";
        margin = mkLiteral "0px";
      };

      "element, element-text, element-icon" = {
        cursor = mkLiteral "pointer";
      };

      "element alternate.normal" = {
        background-color = lib.mkForce (mkLiteral "transparent");
        text-color = lib.mkForce (mkLiteral "@normal-foreground");
      };
      "element alternate.active" = {
        background-color = lib.mkForce (mkLiteral "transparent");
        text-color = lib.mkForce (mkLiteral "@active-foreground");
      };
      "element alternate.urgent" = {
        background-color = lib.mkForce (mkLiteral "transparent");
        text-color = lib.mkForce (mkLiteral "@urgent-foreground");
      };
    };
  };

  xdg.configFile."rofi/app-launcher.rasi".source = ../config/rofi/app-launcher.rasi;
  xdg.configFile."rofi/window-switcher.rasi".source = ../config/rofi/window-switcher.rasi;
  xdg.configFile."rofi/confirm-dialog.rasi".source = ../config/rofi/confirm-dialog.rasi;

  home.file.".local/bin/rofi-window-switcher" = {
    source = ../scripts/rofi-window-switcher.sh;
    executable = true;
  };

  home.file.".local/bin/rofi-launcher" = {
    source = ../scripts/rofi-launcher.sh;
    executable = true;
  };

  home.file.".local/bin/new-workspace" = {
    source = ../scripts/new-workspace.sh;
    executable = true;
  };
}
