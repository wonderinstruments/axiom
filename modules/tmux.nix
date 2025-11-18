{ config, pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    shortcut = "a";
    terminal = "screen-256color";
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      yank
    ];
    extraConfig = with config.lib.stylix.colors.withHashtag; ''
      # Status bar
      set-option -g status "on"
      set -g status-interval 2

      # Set status bar colors using stylix theme
      set-option -g status-fg '${base05}' # foreground
      set-option -g status-bg '${base00}' # background

      # Visual mode colors
      set-option -g mode-style fg='${base0E}',bg='${base02}' # purple fg, visual bg

      # Default statusbar colors
      set-option -g status-style fg='${base05}',bg='${base00}',default

      # ---- Windows ----
      # Default window title colors
      set-window-option -g window-status-style fg='${base03}',bg='${base01}'

      # Default window with an activity alert
      set-window-option -g window-status-activity-style bg='${base01}',fg='${base04}'

      # Active window title colors
      set-window-option -g window-status-current-style fg='${base05}',bg='${base0B}' # fg on green

      # ---- Pane ----
      # Pane borders
      set-option -g pane-border-style fg='${base02}'
      set-option -g pane-active-border-style fg='${base0D}' # blue

      # Pane number display
      set-option -g display-panes-active-colour '${base0D}' # blue
      set-option -g display-panes-colour '${base09}' # orange

      # ---- Command ----
      # Message info
      set-option -g message-style fg='${base08}',bg='${base00}' # red fg

      # Writing commands inactive
      set-option -g message-command-style fg='${base04}',bg='${base01}'

      # ---- Miscellaneous ----
      # Clock
      set-window-option -g clock-mode-colour '${base0D}' # blue

      # Bell
      set-window-option -g window-status-bell-style fg='${base00}',bg='${base08}' # bg on red

      # ---- Formatting ----
      set-option -g status-left-style none
      set -g status-left-length 60
      set -g status-left '#[fg=${base00},bg=${base0B},bold] #S #[fg=${base0B},bg=${base02},nobold]#[fg=${base0B},bg=${base02},bold] #(whoami) #[fg=${base02},bg=${base01},nobold]'

      set-option -g status-right-style none
      set -g status-right-length 150
      set -g status-right '#[fg=${base02}]#[fg=${base05},bg=${base02}] #[fg=${base05},bg=${base02}]%Y-%m-%d  %H:%M #[fg=${base0C},bg=${base02},bold]#[fg=${base00},bg=${base0C},bold] #h '

      set -g window-status-separator '#[fg=${base04},bg=${base01}] '
      set -g window-status-format "#[fg=${base03},bg=${base01}] #I  #[fg=${base03},bg=${base01}]#W "
      set -g window-status-current-format "#[fg=${base01},bg=${base0B}]#[fg=${base00},bg=${base0B}] #I  #[fg=${base00},bg=${base0B},bold]#W #[fg=${base0B},bg=${base01},nobold]"
    '';
  };
}
