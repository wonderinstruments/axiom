{
  description = "Axiom System Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    kickstart = {
      url = "github:nvim-lua/kickstart.nvim";
      flake = false;
    };
    stylix = {
      url = "github:nix-community/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    guide = {
      url = "git+file:///home/edmund/wonderinstruments/guide";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    parental-controls = {
      url = "git+file:///home/edmund/wonderinstruments/parental-controls";
      inputs.nixpkgs.follows = "nixpkgs";
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
      guide,
      nixvim,
      parental-controls,
      ...
    }:
    {
      nixosConfigurations.axiom = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          {
            nixpkgs.overlays = [
              guide.overlays.default
              (final: prev: {
                parental-controls = parental-controls.packages.${prev.system}.default;
              })
            ];
          }
          ./configuration.nix
          stylix.nixosModules.stylix
          guide.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            # home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {
              inherit kickstart;
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
              ./modules/admin.nix
              ./modules/games.nix
              ./modules/rofi.nix
              ./modules/applications.nix
              ./modules/keybindings.nix
              ./modules/docs.nix
              ./modules/fish.nix
              ./modules/i3.nix
              ./modules/polybar.nix
              ./modules/picom.nix
              ./modules/kitty.nix
              ./modules/screen-locker.nix
              ./modules/fractal-wallpaper.nix
              ./modules/sounds.nix
              ./modules/clipboard-monitor.nix
              ./modules/micro.nix
              ./modules/custom-icons.nix
              ./modules/tmux.nix
              ./modules/axiom-python.nix
            ];
            home-manager.users.edmund = {
              imports = [
                ./templates/theme.nix
                ./templates/neovim.nix
                ./templates/admin.nix
                ./templates/keybindings.nix
                ./templates/docs.nix
                ./templates/fractal-wallpaper.nix
                ./templates/sounds.nix
                ./templates/clipboard-monitor.nix
                ./templates/screen-locker.nix
              ];
            };
          }
        ];
      };
    };
}
