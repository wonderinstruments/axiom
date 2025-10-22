{ config, pkgs, ... }:
let
  pidfile = "$HOME/.cache/cmatrix.pid";

  cmatrixSaver = pkgs.writeShellScriptBin "cmatrix-saver" ''
    #!/usr/bin/env bash
    set -euo pipefail
    exec ${pkgs.xterm}/bin/xterm -fullscreen -fa "Monospace" -fs 14 \
         -e ${pkgs.cmatrix}/bin/cmatrix -a -b
  '';

  timeoutCmd = ''${cmatrixSaver}/bin/cmatrix-saver & echo $! > ${pidfile}'';
  cancellerCmd = ''[ -f ${pidfile} ] && kill "$(cat ${pidfile})" 2>/dev/null || true; rm -f ${pidfile}'';
in
{
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
}
