{
  description = "Axiom System Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    kickstart = {
      url = "github:nvim-lua/kickstart.nvim";
      flake = false;
    };
    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gittype = {
      url = "github:unhappychoice/gittype";
    };
    ck = {
      url = "github:BeaconBay/ck";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      kickstart,
      stylix,
      nixvim,
      gittype,
      ck,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Build axiom-rebuild from local source
      axiom-rebuild = pkgs.rustPlatform.buildRustPackage {
        pname = "axiom-rebuild";
        version = "0.1.0";
        src = ./tools/axiom-rebuild;
        cargoLock.lockFile = ./tools/axiom-rebuild/Cargo.lock;
      };

      # Build launcher from local source
      launcher = pkgs.rustPlatform.buildRustPackage {
        pname = "launcher";
        version = "0.1.0";
        src = ./tools/launcher;
        cargoLock.lockFile = ./tools/launcher/Cargo.lock;
      };

      # Build ck from GitHub source
      ck-pkg = pkgs.rustPlatform.buildRustPackage {
        pname = "ck";
        version = "0.1.0";
        src = ck;
        cargoLock.lockFile = "${ck}/Cargo.lock";
        buildAndTestSubdir = "ck-cli";
      };

      # Build guide packages from local source
      guidePackages = rec {
        guide = pkgs.buildGoModule {
          pname = "guide";
          version = "0.1.0";
          src = ./tools/guide;
          vendorHash = "sha256-asGtQIKm05mQHXU8vRKhcNAFzZh0R0z27aReCcHszeo=";
          subPackages = [ "cmd/guide" ];
          nativeBuildInputs = with pkgs; [ pkg-config ];
          ldflags = [
            "-s"
            "-w"
          ];
        };

        guide-llama-launcher = pkgs.buildGoModule {
          pname = "guide-llama-launcher";
          version = "0.1.0";
          src = ./tools/guide;
          vendorHash = guide.vendorHash;
          subPackages = [ "cmd/guide-llama-launcher" ];
          nativeBuildInputs = with pkgs; [ pkg-config ];
          ldflags = [
            "-s"
            "-w"
          ];
        };
      };

      # Guide overlay
      guideOverlay = final: prev: guidePackages;

      # Guide NixOS module
      guideModule = import ./tools/guide/nixos-module.nix;
    in
    {
      # Export axiom-rebuild package
      packages.${system} = {
        axiom-rebuild = axiom-rebuild;
        default = axiom-rebuild;
      };

      nixosConfigurations.axiom = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          {
            nixpkgs.overlays = [
              guideOverlay
              (final: prev: {
                launcher = launcher;
                axiom-rebuild = axiom-rebuild;
                ck = ck-pkg;
              })
            ];
          }
          ./configuration.nix
          stylix.nixosModules.stylix
          guideModule
          home-manager.nixosModules.home-manager
          {
            # home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {
              inherit kickstart gittype;
              launcher = launcher;
              pkgs-unstable = import nixpkgs-unstable {
                system = "x86_64-linux";
                config.allowUnfree = true;
              };
            };
            home-manager.sharedModules = [
              stylix.homeModules.stylix
              nixvim.homeModules.nixvim
              ./home.nix
              ./modules/stylix.nix
              ./modules/neovim.nix
              ./modules/web.nix
              ./modules/rofi.nix
              ./modules/applications.nix
              ./modules/keybindings.nix
              ./modules/docs.nix
              ./modules/python-scripts.nix
              ./modules/bashcrawl.nix
              ./modules/fish.nix
              ./modules/i3.nix
              ./modules/polybar.nix
              ./modules/picom.nix
              ./modules/kitty.nix
              ./modules/screensaver.nix
              ./modules/fractal-wallpaper.nix
              ./modules/sounds.nix
              ./modules/clipboard-monitor.nix
              ./modules/micro.nix
              ./modules/thonny.nix
              ./modules/custom-icons.nix
              ./modules/system-commands.nix
              ./modules/tmux.nix
              ./modules/launcher.nix
              ./modules/file-commands.nix
              ./modules/xplr.nix
              ./modules/navi.nix
              ./modules/musopen.nix
              ./modules/gittype.nix
              ./modules/axiom-config.nix
            ];
            # Per-user configs are generated by axiom-rebuild from HOCON files
            home-manager.users.edmund = {
              imports = [ ./config/users/edmund.nix ];
            };
          }
        ];
      };
    };
}
