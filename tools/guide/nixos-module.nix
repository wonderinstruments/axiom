{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.guide;

  # Download model using fetchurl (streams to disk, doesn't load into RAM)
  qwenModel = pkgs.fetchurl {
    url = "https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-Q8_0.gguf";
    hash = "sha256-CtiF/9S7Ai/E8NM6Mwj6EI74YTFZ07OmfiOrygVremw=";
    name = "Qwen3.5-0.8B-Q8_0.gguf";
  };

  # Configuration file generator
  configFile = pkgs.writeText "config.toml" ''
    [server]
    host = "${cfg.server.host}"
    port = ${toString cfg.server.port}

    [llama]
    binary = "${cfg.llama.package}/bin/llama-server"
    model = "${cfg.llama.modelPath}"
    threads = ${toString cfg.llama.threads}
    ctx_size = ${toString cfg.llama.ctxSize}
    temperature = ${toString cfg.llama.temperature}
    n_gpu_layers = ${toString cfg.llama.gpuLayers}
    batch = ${toString cfg.llama.batchSize}
    rope_freq_base = ${toString cfg.llama.ropeFreqBase}
    rope_freq_scale = ${toString cfg.llama.ropeFreqScale}
    mlock = ${if cfg.llama.mlock then "true" else "false"}
    verbose = ${if cfg.llama.verbose then "true" else "false"}
    extra_args = ${builtins.toJSON cfg.llama.extraArgs}
  '';

in
{
  options.services.guide = {
    enable = mkEnableOption "Guide LLM service";

    package = mkOption {
      type = types.package;
      # No default - must be provided by the user or via overlay
      description = "The guide package to use";
    };

    launcherPackage = mkOption {
      type = types.package;
      # No default - must be provided by the user or via overlay
      description = "The guide-llama-launcher package to use";
    };

    user = mkOption {
      type = types.str;
      default = "guide";
      description = "User account under which guide runs";
    };

    group = mkOption {
      type = types.str;
      default = "guide";
      description = "Group under which guide runs";
    };

    server = {
      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Server host to bind to";
      };

      port = mkOption {
        type = types.port;
        default = 8234;
        description = "Server port to bind to";
      };
    };

    llama = {
      package = mkOption {
        type = types.package;
        default = pkgs.llama-cpp;
        description = "The llama-cpp package to use";
      };

      modelPath = mkOption {
        type = types.str;
        default = "${qwenModel}";
        defaultText = "Qwen3.5-0.8B model fetched via Nix";
        description = "Path to the GGUF model file (defaults to bundled model)";
      };

      threads = mkOption {
        type = types.int;
        default = 0;
        description = "Number of CPU threads (0 = auto-detect)";
      };

      ctxSize = mkOption {
        type = types.int;
        default = 4096;
        description = "Context size in tokens";
      };

      temperature = mkOption {
        type = types.float;
        default = 0.7;
        description = "Temperature for sampling";
      };

      gpuLayers = mkOption {
        type = types.int;
        default = 0;
        description = "Number of GPU layers to offload (0 = CPU only)";
      };

      batchSize = mkOption {
        type = types.int;
        default = 512;
        description = "Batch size for prompt processing";
      };

      ropeFreqBase = mkOption {
        type = types.float;
        default = 0.0;
        description = "RoPE frequency base (0.0 = model default)";
      };

      ropeFreqScale = mkOption {
        type = types.float;
        default = 0.0;
        description = "RoPE frequency scale (0.0 = model default)";
      };

      mlock = mkOption {
        type = types.bool;
        default = false;
        description = "Lock model in RAM (prevents swapping)";
      };

      verbose = mkOption {
        type = types.bool;
        default = false;
        description = "Enable verbose logging";
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Additional command-line arguments for llama-server";
      };
    };

    ompNumThreads = mkOption {
      type = types.nullOr types.int;
      default = 8;
      description = "OMP_NUM_THREADS environment variable (null to not set)";
    };
  };

  config = mkIf cfg.enable {
    # Create user and group
    users.users = mkIf (cfg.user == "guide") {
      guide = {
        isSystemUser = true;
        group = cfg.group;
        description = "Guide LLM service user";
      };
    };

    users.groups = mkIf (cfg.group == "guide") {
      guide = { };
    };

    # Main service
    systemd.services.guide-llama-server = {
      description = "Guide llama-server";
      documentation = [ "https://github.com/wonderinstruments/guide" ];
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.launcherPackage}/bin/guide-llama-launcher";
        Restart = "always";
        RestartSec = "2s";

        # Resource limits
        LimitNOFILE = 65536;

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "full";
        ProtectHome = "read-only";
        PrivateTmp = true;

        # Logging
        StandardOutput = "journal";
        StandardError = "journal";
      };

      environment = {
        GUIDE_CONFIG = "/etc/guide/config.toml";
      }
      // (optionalAttrs (cfg.ompNumThreads != null) {
        OMP_NUM_THREADS = toString cfg.ompNumThreads;
      });
    };

    # Install configuration
    environment.etc."guide/config.toml".source = configFile;

    # Install guide client system-wide
    environment.systemPackages = [ cfg.package ];
  };
}
