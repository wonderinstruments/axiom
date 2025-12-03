{
  description = "TUI Application Launcher";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        pname = "launcher";
        version = "0.1.0";

        src = ./.;

        dontBuild = true;
        dontConfigure = true;

        installPhase = ''
          mkdir -p $out/bin
          cp target/release/launcher $out/bin/launcher
          chmod +x $out/bin/launcher
        '';

        meta = {
          description = "TUI Application Launcher with icon support";
          homepage = "https://github.com/yourusername/launcher";
          license = pkgs.lib.licenses.mit;
          mainProgram = "launcher";
        };
      };

      # For development
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          cargo
          rustc
          rust-analyzer
          pkg-config
        ];
      };
    };
}
