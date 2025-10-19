{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    {
      nixosConfigurations.axiom = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.edmund =
              { pkgs, ... }:
              {
                home.stateVersion = "25.05";
                xsession.windowManager.i3 = {
                  enable = true;
                  config = {
                    modifier = "Mod4";
                    terminal = "kitty";
                    keybindings = {
                      "Mod4+Return" = "exec kitty";
                    };
                  };
                };
              };
          }
        ];
      };
    };
}
