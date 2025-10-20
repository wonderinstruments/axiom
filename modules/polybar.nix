{ config, pkgs, ... }:

{
  # Create polybar configuration
  environment.etc."polybar/config.ini".text = ''
    [colors]
    background = #282A2E
    background-alt = #373B41
    foreground = #C5C8C6
    primary = #F0C674
    secondary = #8ABEB7
    alert = #A54242
    disabled = #707880

    [bar/main]
    width = 100%
    height = 24pt
    radius = 0

    background = ''${colors.background}
    foreground = ''${colors.foreground}

    line-size = 3pt

    border-size = 0pt
    border-color = #00000000

    padding-left = 0
    padding-right = 1

    module-margin = 1

    separator = |
    separator-foreground = ''${colors.disabled}

    font-0 = monospace;2

    modules-left = xworkspaces xwindow
    modules-right = filesystem pulseaudio xkeyboard memory cpu wlan eth date

    cursor-click = pointer
    cursor-scroll = ns-resize

    enable-ipc = true

    [module/xworkspaces]
    type = internal/xworkspaces

    label-active = %name%
    label-active-background = ''${colors.background-alt}
    label-active-underline= ''${colors.primary}
    label-active-padding = 1

    label-occupied = %name%
    label-occupied-padding = 1

    label-urgent = %name%
    label-urgent-background = ''${colors.alert}
    label-urgent-padding = 1

    label-empty = %name%
    label-empty-foreground = ''${colors.disabled}
    label-empty-padding = 1

    [module/xwindow]
    type = internal/xwindow
    label = %title:0:60:...%

    [module/filesystem]
    type = internal/fs
    interval = 25

    mount-0 = /

    label-mounted = %{F#F0C674}%mountpoint%%{F-} %percentage_used%%

    label-unmounted = %mountpoint% not mounted
    label-unmounted-foreground = ''${colors.disabled}

    [module/pulseaudio]
    type = internal/pulseaudio

    format-volume-prefix = "VOL "
    format-volume-prefix-foreground = ''${colors.primary}
    format-volume = <label-volume>

    label-volume = %percentage%%

    label-muted = muted
    label-muted-foreground = ''${colors.disabled}

    [module/xkeyboard]
    type = internal/xkeyboard
    blacklist-0 = num lock

    label-layout = %layout%
    label-layout-foreground = ''${colors.primary}

    label-indicator-padding = 2
    label-indicator-margin = 1
    label-indicator-foreground = ''${colors.background}
    label-indicator-background = ''${colors.secondary}

    [module/memory]
    type = internal/memory
    interval = 2
    format-prefix = "RAM "
    format-prefix-foreground = ''${colors.primary}
    label = %percentage_used:2%%

    [module/cpu]
    type = internal/cpu
    interval = 2
    format-prefix = "CPU "
    format-prefix-foreground = ''${colors.primary}
    label = %percentage:2%%

    [module/wlan]
    type = internal/network
    interface-type = wireless
    interval = 3.0

    format-connected = <ramp-signal> <label-connected>
    label-connected = %essid% %local_ip%

    format-disconnected = <label-disconnected>
    label-disconnected = %ifname% disconnected
    label-disconnected-foreground = ''${colors.disabled}

    ramp-signal-0 = 😱
    ramp-signal-1 = 😠
    ramp-signal-2 = 😒
    ramp-signal-3 = 😊
    ramp-signal-4 = 😃
    ramp-signal-5 = 😈

    [module/eth]
    type = internal/network
    interface-type = wired
    interval = 3.0

    format-connected-prefix = "ETH "
    format-connected-prefix-foreground = ''${colors.primary}
    format-connected = <label-connected>

    label-connected = %local_ip%

    format-disconnected = <label-disconnected>
    label-disconnected = %ifname% disconnected
    label-disconnected-foreground = ''${colors.disabled}

    [module/date]
    type = internal/date
    interval = 1

    date = %H:%M
    date-alt = %Y-%m-%d %H:%M:%S

    label = %date%
    label-foreground = ''${colors.primary}

    [settings]
    screenchange-reload = true
    pseudo-transparency = true
  '';

  # Service to start polybar
  systemd.user.services.polybar = {
    description = "Polybar system information bar";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "forking";
      ExecStart = "${pkgs.polybar}/bin/polybar main";
      Environment = "PATH=${pkgs.polybar}/bin";
      Restart = "on-failure";
    };
  };
}
