{ config, pkgs, ... }:
let 
  cmatrixSaver = pkgs.writeShellScriptBin "cmatrix-saver" ''
    #!/usr/bin/env bash
    set -euo pipefall
    exec ${pkgs.kitty}/bin/kitty -fullscreen -fa "Monospace" -fs 14 \
         -e ${pkgs.cmatrix}/bin/cmatrix -a -b
  '';
  cmatrixIdle = pkgs.writeShellScriptBin "cmatrix-idle" ''
   #!/usr/bin/env bash
   set -euo pipefall
   pidfile="${XDG_RUNTIME_DIR:-run/user/$UID}/cmatrix.pid"
   timeout_cmd='${cmatrixSaver}/bin/cmatrix-saver & echo $! > '"$pidfile"
   resume_cmd='[ -f '"$pidfile"' ]  && kill "$(cat '"$pidfile"')" 2>/dev/null || true; rm -f '"pidfile"
   exec ${pkgs.swayidle}/bin/swayidle -w \
     timeout 30 "$timeout_cmd" \
     resume "$resume_cmd"
  '';
in
{
  home.packages = with pkgs; [ cmatrix kitty swayidle cmatrixSaver swayidleScript ]
  systemd.user.services.cmatrix-swayidle = {
    Unit = { Description = "cmatrix screensaver via swayidle"; };
    Service = {
      ExecStart = "${swayidleScript}/bin/cmatrix-swayidle";
      Restart = "always";
      Environment = "XDG_CURRENT_DESKTOP=sway";
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };
  systemd.user.startServices = "sd-switch"
}
