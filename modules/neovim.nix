{
  lib,
  pkgs,
  config,
  kickstart,
  ...
}:
let
  cfg = config.axiom.neovim;

  # Paths we’ll use
  cfgDir = "${config.xdg.configHome}/nvim"; # ~/.config/nvim
  pristineDir = "${config.xdg.dataHome}/nvim/kickstart-pristine"; # ~/.local/share/nvim/kickstart-pristine
in
{
  options.axiom.neovim = {
    # Copy pristine -> ~/.config/nvim ONLY if the target is missing/empty.
    seedIfMissing = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Seed ~/.config/nvim from a pristine Kickstart copy if missing/empty.";
    };

    # Force a wipe + re-seed on the next `home-manager switch` (then set back to false yourself).
    resetOnNextSwitch = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "If true, remove ~/.config/nvim and reseed from pristine on next switch.";
    };

    # Append this Lua to the end of init.lua after seeding (idempotent; re-applied each switch).
    extraLua = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Lua snippet appended to ~/.config/nvim/init.lua after seeding.";
    };

    # Declarative overlay files under ~/.config/nvim/user/*
    userFiles = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Map of relative path -> file text placed under ~/.config/nvim/user/";
    };

    # Handy CLIs for Telescope/LSP/etc.
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        ripgrep
        fd
        gcc
        gnumake
        git
        unzip
        curl
      ];
      description = "Extra CLI tools available to Neovim (PATH).";
    };
  };

  config = {
    programs.neovim = {
      enable = true;
      plugins = [ ]; # let Lazy from Kickstart manage plugins
      withNodeJs = true;
      withPython3 = true;
      extraPackages = cfg.extraPackages;
    };

    # Keep a read-only pristine copy in XDG data (Nix-managed, not in the editable config dir)
    xdg.dataFile."nvim/kickstart-pristine".source = kickstart;

    # Optional overlay files under ~/.config/nvim/user/*
    xdg.configFile = lib.mapAttrs' (
      name: text: lib.nameValuePair ("nvim/user/" + name) { inherit text; }
    ) cfg.userFiles;

    # Append extraLua to ~/.config/nvim/init.lua after seeding (idempotent edit)
    home.activation.myNeovim_appendExtraLua = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      if [ -n "${lib.escapeShellArg cfg.extraLua}" ]; then
        if [ -f "${cfgDir}/init.lua" ]; then
          # Append exactly once by guarding with a marker
          if ! grep -q "---- HM extraLua (do not edit above this line) ----" "${cfgDir}/init.lua"; then
            {
              echo ""
              echo "---- HM extraLua (do not edit above this line) ----"
              printf '%s\n' ${lib.escapeShellArg cfg.extraLua}
            } >> "${cfgDir}/init.lua"
          fi
        fi
      fi
    '';

    # Seeding / Reset logic
    home.activation.myNeovim_seedOrReset = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu

      # If requested, wipe and reseed
      if ${lib.boolToString cfg.resetOnNextSwitch}; then
        echo "[myNeovim] Reset requested: removing ${cfgDir} and reseeding from pristine."
        rm -rf "${cfgDir}"
      fi

      # Seed when init.lua is missing (directory might exist due to userFiles)
      if ${lib.boolToString cfg.seedIfMissing}; then
        if [ ! -f "${cfgDir}/init.lua" ]; then
          echo "[myNeovim] Seeding ${cfgDir} from pristine Kickstart (init.lua missing)."
          mkdir -p "${cfgDir}"
          # Copy everything but don't overwrite existing files
          if command -v rsync >/dev/null 2>&1; then
            rsync -a --ignore-existing "${pristineDir}/" "${cfgDir}/"
          else
            # cp -n is fine as a fallback
            cp -Rn --no-preserve=mode,ownership "${pristineDir}/." "${cfgDir}/" || true
          fi
        else
          echo "[myNeovim] ${cfgDir}/init.lua exists; not touching user edits."
        fi
      fi
    '';

  };
}
