{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.axiom.screensaver;
  pidfile = "$HOME/.cache/cmatrix.pid";

  cmatrixSaver = pkgs.writeShellScriptBin "cmatrix-saver" ''
    #!/usr/bin/env bash
    set -euo pipefail

    children=()

    cleanup() {
      # Kill all children of this script's process group
      # This covers the background subshells and their xterms
      kill 0 2>/dev/null || true
    }
    trap cleanup EXIT

    # Get all connected outputs
    outputs=$(${pkgs.xorg.xrandr}/bin/xrandr --query | ${pkgs.gnugrep}/bin/grep " connected" | ${pkgs.coreutils}/bin/cut -d" " -f1)

    # Start one cmatrix xterm per output with a unique title
    idx=0
    for output in $outputs; do
      idx=$((idx + 1))
      title="cmatrix-saver-$idx"

      # Start xterm and immediately assign it to the correct output via i3-msg
      # We use a subshell to start it, grab its PID, and then move it
      (
        # Trap SIGINT so if one xterm is killed (Ctrl+C), this subshell exits
        # and triggers the main script's cleanup via the process group.
        trap "exit 0" INT

        ${pkgs.xterm}/bin/xterm -title "$title" -fa "Monospace" -fs 14 \
           -xrm "XTerm*pointerShape: none" \
           -xrm "XTerm*borderWidth: 0" \
           -xrm "XTerm*internalBorder: 0" \
           +pc \
           -e ${cfg.command} &
        pid=$!
        
        # Wait for window to exist
        until ${pkgs.i3}/bin/i3-msg "[title=\"$title\"] focus" >/dev/null 2>&1; do
           if ! kill -0 $pid 2>/dev/null; then break; fi
           sleep 0.1
        done

        # Move to correct output and enforce fullscreen again explicitly
        ${pkgs.i3}/bin/i3-msg "[title=\"$title\"] move window to output $output" >/dev/null 2>&1 || true
        sleep 0.2
        ${pkgs.i3}/bin/i3-msg "[title=\"$title\"] fullscreen enable" >/dev/null 2>&1 || true

        # Wait for the xterm to finish
        wait $pid
        
        # If xterm exits (e.g. user Ctrl+C in that window), kill the whole group
        kill 0
      ) &
      
      # We can't track the exact PID easily in this subshell structure for the main cleanup,
      # but the 'children' array tracking needs to know pids.
      # Instead of complex PID passing, we'll rely on pkill/cleanup finding them 
      # or just let the trap kill the process group if possible.
      # For now, let's sleep slightly to avoid race conditions between starting multiple xterms
      sleep 0.2
    done

    # Get all connected monitors and their geometries for the help bar overlay
    monitors=$(${pkgs.xorg.xrandr}/bin/xrandr | ${pkgs.gnugrep}/bin/grep " connected" | ${pkgs.gnugrep}/bin/grep -oP '[0-9]+x[0-9]+\+[0-9]+\+[0-9]+')

    for geometry in $monitors; do
      if [[ "$geometry" =~ ([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+) ]]; then
        width="''${BASH_REMATCH[1]}"
        height="''${BASH_REMATCH[2]}"
        x="''${BASH_REMATCH[3]}"
        y="''${BASH_REMATCH[4]}"

        (echo "Press Ctrl+c to escape" | ${pkgs.dzen2}/bin/dzen2 \
          -x "$x" -y "$((y + height - 30))" -w "$width" -h 30 \
          -ta c \
          -fn "${config.stylix.fonts.monospace.name}:pixelsize=18" \
          -fg "#${config.lib.stylix.colors.base0B}" \
          -bg "#${config.lib.stylix.colors.base00}" -e "onstart=uncollapse" -p) &
        dzen_pid=$!
        children+=("$dzen_pid")
      fi
    done

    wait
  '';

  startScreensaver = pkgs.writeShellScriptBin "start-screensaver" ''
    #!/usr/bin/env bash
    set -euo pipefail

    PIDFILE="${pidfile}"

    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
      echo "cmatrix-saver already running (PID $(cat "$PIDFILE"))" >&2
      exit 1
    fi

    ${cmatrixSaver}/bin/cmatrix-saver &
    echo $! > "$PIDFILE"
  '';

  timeoutCmd = ''${cmatrixSaver}/bin/cmatrix-saver & echo $! > ${pidfile}'';
  cancellerCmd = ''[ -f ${pidfile} ] && kill "$(cat ${pidfile})" 2>/dev/null || true; rm -f ${pidfile}'';
in
{
  options = {
    axiom.screensaver = {
      enable = lib.mkEnableOption "screensaver";
      sleepAfterMinutes = lib.mkOption {
        type = lib.types.int;
        default = 15;
        description = "Idle timeout in minutes before the screensaver starts.";
      };
      command = lib.mkOption {
        type = lib.types.str;
        default = "${pkgs.cmatrix}/bin/cmatrix -a -b";
        description = "Command to run as the screensaver.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      cmatrix
      cmatrixSaver
      startScreensaver
      dzen2
      i3
    ];

    services.xidlehook = {
      enable = true;
      timers = [
        {
          delay = cfg.sleepAfterMinutes * 60;
          command = timeoutCmd;
          canceller = cancellerCmd;
        }
      ];
    };
  };
}
