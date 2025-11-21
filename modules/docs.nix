{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.docs;

  # Scripts from scripts directory
  welcomeScript = builtins.readFile ../scripts/welcome.py;
  generateFractalScript = builtins.readFile ../scripts/generate_fractal.py;
  setWallpaperScript = builtins.readFile ../scripts/set_wallpaper.py;
  fractalSaverScript = builtins.readFile ../scripts/fractal_saver.py;

  # Documentation files from the docs directory
  docTemplates = {
    "docs/WELCOME.md" = builtins.readFile ../docs/WELCOME.md;

    "docs/TERMINAL.md" = builtins.readFile ../docs/TERMINAL.md;

    "docs/TEXT_EDITOR.md" = builtins.readFile ../docs/TEXT_EDITOR.md;

    "docs/WINDOWS.md" = builtins.readFile ../docs/WINDOWS.md;
  };
in
{
  options.axiom.docs = {
    # Enable documentation deployment
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable deployment of documentation files.";
    };

    # Whether to overwrite existing docs
    overwrite = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to overwrite existing documentation files.";
    };

    # Custom documentation files (can override defaults)
    customDocs = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Map of relative path -> file content for custom documentation files.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Deploy documentation files and scripts using home.file for direct file management
    home.file =
      let
        # Merge default templates with custom docs
        allDocs = docTemplates // cfg.customDocs;

        # Create file entries with force option based on overwrite setting
        createFileEntry =
          name: content:
          lib.nameValuePair name {
            text = content;
            force = cfg.overwrite;
          };
      in
      (lib.mapAttrs' createFileEntry allDocs)
      // {
        # Deploy scripts
        "scripts/welcome.py" = {
          text = welcomeScript;
          executable = true;
          force = cfg.overwrite;
        };
        "scripts/generate_fractal.py" = {
          text = generateFractalScript;
          executable = true;
          force = cfg.overwrite;
        };
        "scripts/set_wallpaper.py" = {
          text = setWallpaperScript;
          executable = true;
          force = cfg.overwrite;
        };
        "scripts/fractal_saver.py" = {
          text = fractalSaverScript;
          executable = true;
          force = cfg.overwrite;
        };
      };

    # Ensure the docs and scripts directories exist
    home.activation.docsDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      mkdir -p "$HOME/docs"
      mkdir -p "$HOME/scripts"
    '';
  };
}
