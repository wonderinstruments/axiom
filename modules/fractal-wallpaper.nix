{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types mkIf;
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
    base00 base01 base02 base03 base04 base05 base06 base07
    base08 base09 base0A base0B base0C base0D base0E base0F
  ];

  # Generate the fractal command
  generateCommand = ''
    ${fractal-generator}/bin/fractal-wallpaper \
      --output ${wallpaperPath} \
      --width ${toString cfg.width} \
      --height ${toString cfg.height} \
      --type ${cfg.fractalType} \
      --iterations ${toString cfg.iterations} \
      --zoom ${toString cfg.zoom} \
      --center-x ${toString cfg.centerX} \
      --center-y ${toString cfg.centerY} \
      --julia-c-real ${toString cfg.juliaCReal} \
      --julia-c-imag ${toString cfg.juliaCImag} \
      --colors ${lib.concatStringsSep " " colorsList}
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
      type = types.enum [ "mandelbrot" "julia" ];
      default = "mandelbrot";
      description = "Type of fractal to generate";
    };

    iterations = mkOption {
      type = types.int;
      default = 256;
      description = "Maximum iterations for fractal calculation";
    };

    zoom = mkOption {
      type = types.float;
      default = 1.0;
      description = "Zoom level for the fractal";
    };

    centerX = mkOption {
      type = types.float;
      default = -0.5;
      description = "X coordinate of the fractal center";
    };

    centerY = mkOption {
      type = types.float;
      default = 0.0;
      description = "Y coordinate of the fractal center";
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
    # Ensure feh is available
    home.packages = [ pkgs.feh ];

    # Generate wallpaper on activation
    home.activation.generateFractalWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
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
