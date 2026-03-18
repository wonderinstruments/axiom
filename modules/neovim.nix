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
    resetConfigFileOnNextSwitch = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "If true, remove ~/.config/nvim and reseed from pristine on next switch.";
    };

    configureByConfigFile = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "If true, use kickstart.nvim to configure neovim instead of nix";
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

  config =
    lib.mkIf cfg.configureByConfigFile {
      programs.neovim = {
        enable = true;
        plugins = [ ]; # let Lazy from Kickstart manage plugins
        withNodeJs = true;
        withPython3 = true;
        extraPackages = cfg.extraPackages;
      };
      stylix.targets.neovim.enable = false; # using kickstart config

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
        if ${lib.boolToString cfg.resetConfigFileOnNextSwitch}; then
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
    }
    // lib.mkIf (!cfg.configureByConfigFile) {
      stylix.targets.nixvim.enable = false; # incompatible with current nixvim version
      programs.nixvim = {
        enable = true;
        opts = {
          number = true;
          relativenumber = true;
          smartindent = true;
          autoindent = true;
          signcolumn = "yes";
          ignorecase = true;
          smartcase = true;
          clipboard = {
            register = "unnamedplus";
          };
        };
        plugins = {
          sleuth.enable = true;
          oil.enable = true;
          comment.enable = true;
          web-devicons.enable = true;
          tmux-navigator.enable = true;
          conform-nvim.enable = true;
          todo-comments.enable = true;
          telescope = {
            enable = true;
            extensions = {
              fzf-native.enable = true;
              ui-select.enable = true;
              file-browser.enable = true;
            };
          };
          treesitter = {
            enable = true;
            nixGrammars = true;
            settings.highlight.enable = true;
          };
          lsp = {
            enable = true;
            servers = {
              nixd.enable = true;
              pyright.enable = true;
            };
          };
        };
        globals.mapleader = " ";
        plugins.telescope.keymaps = {
          "<leader>f" = {
            action = "find_files";
          };
          "<leader>g" = {
            action = "live_grep";
          };
        };
        keymaps = [
          {
            action = "<cmd>Oil<CR>";
            key = "-";
          }
          {
            action = "<cmd>call system('canberra-gtk-play -i oops 2>/dev/null &') | echo \"Use :q to quit!! (or :wq to save and quit)\"<CR>";
            key = "<esc>";
          }
          {
            action = "<cmd>call system('canberra-gtk-play -i oops 2>/dev/null &') | echo \"Use h to move!!\"<CR>";
            key = "<left>";
          }
          {
            action = "<cmd>call system('canberra-gtk-play -i oops 2>/dev/null &') | echo \"Use l to move!!\"<CR>";
            key = "<right>";
          }
          {
            action = "<cmd>call system('canberra-gtk-play -i oops 2>/dev/null &') | echo \"Use k to move!!\"<CR>";
            key = "<up>";
          }
          {
            action = "<cmd>call system('canberra-gtk-play -i oops 2>/dev/null &') | echo \"Use j to move!!\"<CR>";
            key = "<down>";
          }
        ];
      };
    };
}
