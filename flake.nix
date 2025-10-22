{
  description = "Axiom System Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    kickstart = {
      url = "github:nvim-lua/kickstart.nvim";
      flake = false;
    };
    stylix = {
      url = "github:nix-community/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      kickstart,
      stylix,
      ...
    }:
    {
      nixosConfigurations.axiom = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          {
            # home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit kickstart;
            };
            home-manager.sharedModules = [
              stylix.homeModules.stylix
              ./home.nix
              ./modules/stylix.nix
              ./modules/neovim.nix
              ./modules/admin.nix
              ./modules/rofi.nix
              ./modules/applications.nix
              ./modules/keybindings.nix
              ./modules/docs.nix
              ./modules/fish.nix
              ./modules/i3.nix
              ./modules/kitty.nix
              ./modules/screen-locker.nix
            ];
            home-manager.users.edmund = {
              imports = [
                ./templates/theme.nix
                ./templates/neovim.nix
                ./templates/admin.nix
                ./templates/keybindings.nix
                ./templates/docs.nix
                ./templates/terminal.nix
              ];
            };
          }
        ];
      };
    };
}
