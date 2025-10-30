{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    types
    mkIf
    ;
  cfg = config.axiom.fractal-wallpaper;

  # Create a Python package with the fractal generator script
  fractal-generator = pkgs.python3.pkgs.buildPythonApplication {
    pname = "fractal-wallpaper";
    version = "1.0.0";

    src = ../scripts;

    format = "other";

    propagatedBuildInputs = with pkgs.python3.pkgs; [
      pillow
      numpy
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp fractal-wallpaper.py $out/bin/fractal-wallpaper
      chmod +x $out/bin/fractal-wallpaper
    '';
  };

  # Build the wallpaper file path
  wallpaperPath = "${config.home.homeDirectory}/.cache/fractal-wallpaper.png";

  # Build the colors list from stylix
  colorsList = with config.lib.stylix.colors; [
    base00
    base01
    base02
    base03
    base04
    base05
    base06
    base07
    base08
    base09
    base0A
    base0B
    base0C
    base0D
    base0E
    base0F
  ];

  # Generate the fractal command
  generateCommand = ''
    ${fractal-generator}/bin/fractal-wallpaper \
      --output ${wallpaperPath} \
      --width ${toString cfg.width} \
      --height ${toString cfg.height} \
      --type ${cfg.fractalType} \
      --iterations ${toString cfg.iterations} \
      --search-depth ${toString cfg.searchDepth} \
      --julia-c-real ${toString cfg.juliaCReal} \
      --julia-c-imag ${toString cfg.juliaCImag} \
      --colors ${lib.concatStringsSep " " colorsList}
  '';

  # Create a wrapper script for regenerating the wallpaper
  regenerate-script = pkgs.writeShellScriptBin "regenerate-fractal" ''
    #!/usr/bin/env bash
    echo "Regenerating fractal wallpaper..."
    ${generateCommand}
    echo "Setting wallpaper..."
    ${pkgs.feh}/bin/feh --bg-scale ${wallpaperPath}
    echo "Done!"
  '';
in
{
  options.axiom.fractal-wallpaper = {
    enable = mkEnableOption "fractal wallpaper generation";

    width = mkOption {
      type = types.int;
      default = 1920;
      description = "Width of the generated wallpaper";
    };

    height = mkOption {
      type = types.int;
      default = 1080;
      description = "Height of the generated wallpaper";
    };

    fractalType = mkOption {
      type = types.enum [
        "mandelbrot"
        "julia"
      ];
      default = "mandelbrot";
      description = "Type of fractal to generate";
    };

    iterations = mkOption {
      type = types.int;
      default = 256;
      description = "Maximum iterations for fractal calculation";
    };

    searchDepth = mkOption {
      type = types.int;
      default = 3;
      description = "Depth of recursive search for interesting regions (higher = more zoomed in)";
    };

    juliaCReal = mkOption {
      type = types.float;
      default = -0.7;
      description = "Real part of C for Julia set";
    };

    juliaCImag = mkOption {
      type = types.float;
      default = 0.27015;
      description = "Imaginary part of C for Julia set";
    };
  };

  config = mkIf cfg.enable {
    # Ensure feh is available and install regenerate script
    home.packages = [
      pkgs.feh
      regenerate-script
    ];

    # Generate wallpaper on activation
    home.activation.generateFractalWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${config.home.homeDirectory}/.cache
      run ${generateCommand}
    '';

    # Set the wallpaper using feh in i3 startup
    xsession.windowManager.i3.config.startup = [
      {
        command = "${pkgs.feh}/bin/feh --bg-scale ${wallpaperPath}";
        always = true;
        notification = false;
      }
    ];
  };
}
