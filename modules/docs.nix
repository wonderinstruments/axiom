{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.docs;

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
    # Deploy documentation files using home.file for direct file management
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
      (lib.mapAttrs' createFileEntry allDocs);

    # Ensure the docs directory exists
    home.activation.docsDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      mkdir -p "$HOME/docs"
    '';
  };
}
