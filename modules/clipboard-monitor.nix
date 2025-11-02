{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.axiom.clipboardMonitor;
in
{
  options.axiom.clipboardMonitor = {
    enable = lib.mkEnableOption "clipboard copy sound notifications";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.clipnotify
      pkgs.xclip
    ];

    systemd.user.services.clipboard-monitor = {
      Unit = {
        Description = "Clipboard monitor - play sound on copy";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.writeShellScript "clipboard-monitor" ''
          prev_clip=""
          prev_prim=""
          while ${pkgs.clipnotify}/bin/clipnotify -s clipboard,primary; do
            curr_clip="$(${pkgs.xclip}/bin/xclip -selection clipboard -o 2>/dev/null || true)"
            curr_prim="$(${pkgs.xclip}/bin/xclip -selection primary -o 2>/dev/null || true)"
            
            # Only play sound if clipboard changed but primary didn't (explicit copy)
            if [ "$curr_clip" != "$prev_clip" ] && [ "$curr_prim" = "$prev_prim" ] && [ -n "$curr_clip" ]; then
              ${pkgs.libcanberra-gtk3}/bin/canberra-gtk-play -c never -i copy 2>/dev/null &
            fi
            
            prev_clip="$curr_clip"
            prev_prim="$curr_prim"
          done
        ''}";
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
