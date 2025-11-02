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
    systemd.user.services.clipboard-monitor = {
      Unit = {
        Description = "Clipboard monitor - play sound on copy";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.writeShellScript "clipboard-monitor" ''
          ${pkgs.xsel}/bin/xsel --clipboard --output --watch | while read -r _; do
            ${pkgs.libcanberra-gtk3}/bin/canberra-gtk-play -c never -i copy 2>/dev/null &
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
