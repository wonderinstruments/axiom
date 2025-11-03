{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.axiom.screenLocker;
  pidfile = "$HOME/.cache/cmatrix.pid";

  cmatrixSaver = pkgs.writeShellScriptBin "cmatrix-saver" ''
    #!/usr/bin/env bash
    set -euo pipefail
    exec ${pkgs.xterm}/bin/xterm -fullscreen -fa "Monospace" -fs 14 \
         -xrm "XTerm*pointerShape: none" +pc \
         -e ${pkgs.cmatrix}/bin/cmatrix -a -b
  '';

  timeoutCmd = ''${cmatrixSaver}/bin/cmatrix-saver & echo $! > ${pidfile}'';
  cancellerCmd = ''[ -f ${pidfile} ] && kill "$(cat ${pidfile})" 2>/dev/null || true; rm -f ${pidfile}'';
in
{
  options = {
    axiom.screenLocker = {
      enable = lib.mkEnableOption "cmatrix screensaver";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      cmatrix
      cmatrixSaver
    ];

    services.xidlehook = {
      enable = true;
      timers = [
        {
          delay = 120;
          command = timeoutCmd;
          canceller = cancellerCmd;
        }
      ];
    };
  };
}
