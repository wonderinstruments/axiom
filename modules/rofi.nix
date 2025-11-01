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
      window-command = "wmctrl -i -R {window}";
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

    # Custom theme using attribute set - stylix will handle colors
    theme = {
      "*" = {
        padding = mkLiteral "0px";
        margin = mkLiteral "0px";
      };

      window = {
        fullscreen = true;
        padding = mkLiteral "1em";
      };

      mainbox = {
        padding = mkLiteral "8px";
        children = map mkLiteral [
          "inputbar"
          "listview"
        ];
      };

      inputbar = {
        margin = mkLiteral "0px calc( 50% - 300px )";
        padding = mkLiteral "8px 12px";
        spacing = mkLiteral "8px";
        border = mkLiteral "2px";
        border-radius = mkLiteral "4px";
        children = map mkLiteral [
          "icon-search"
          "entry"
        ];
      };

      prompt = {
        enabled = false;
      };

      "icon-search" = {
        expand = false;
        filename = "search";
        vertical-align = mkLiteral "0.5";
      };

      entry = {
        placeholder = "Search";
        width = mkLiteral "580px";
      };

      listview = {
        margin = mkLiteral "48px calc( 50% - 560px )";
        spacing = mkLiteral "48px";
        columns = 6;
        flow = mkLiteral "horizontal";
        cycle = true;
        fixed-columns = true;
      };

      "element, element-text, element-icon" = {
        cursor = mkLiteral "pointer";
      };

      element = {
        padding = mkLiteral "8px";
        spacing = mkLiteral "4px";
        orientation = mkLiteral "vertical";
        border-radius = mkLiteral "16px";
      };

      "element-icon" = {
        size = mkLiteral "4em";
        horizontal-align = mkLiteral "0.5";
      };

      "element-text" = {
        horizontal-align = mkLiteral "0.5";
      };
    };
  };
}
