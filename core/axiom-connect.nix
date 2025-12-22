# NixOS module for axiom-connect system-wide agent service
# This runs the agent as a system service for the entire device
{ config, lib, pkgs, ... }:

let
  cfg = config.services.axiom-connect;
in
{
  options.services.axiom-connect = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the axiom-connect agent service";
    };

    serverUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://curator.wonderinstruments.com";
      description = "URL of the Curator server";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure the config directory exists
    systemd.tmpfiles.rules = [
      "d /etc/axiom-connect 0755 root root -"
    ];

    # Create initial config file if server URL is set
    environment.etc."axiom-connect/config.toml" = lib.mkIf (cfg.serverUrl != "") {
      text = ''
        server_url = "${cfg.serverUrl}"
      '';
      mode = "0644";
    };

    # Install axiom-connect system-wide
    environment.systemPackages = [ pkgs.axiom-connect ];

    # System service for the agent
    systemd.services.axiom-connect-agent = {
      description = "Axiom Connect Agent";
      documentation = [ "https://github.com/wonderinstruments/axiom" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.axiom-connect}/bin/axiom-connect agent start";
        Restart = "always";
        RestartSec = "10s";

        # Security hardening
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        PrivateTmp = true;
        NoNewPrivileges = true;

        # Allow reading/writing config
        ReadWritePaths = [ "/etc/axiom-connect" "/etc/axiom" ];

        # Logging
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "axiom-connect";
      };

      # Wait for device to be registered before starting
      # The service will wait internally if no device token is configured
    };
  };
}
