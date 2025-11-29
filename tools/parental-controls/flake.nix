{
  description = "Parental Controls - A Wails application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "parental-controls";
          version = "0.1.0";

          src = pkgs.lib.cleanSourceWith {
            src = ./.;
            filter = path: type:
              let baseName = baseNameOf path;
              in baseName == "build" || 
                 pkgs.lib.hasPrefix (toString ./build) path;
          };

          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
          ];

          buildInputs = with pkgs; [
            webkitgtk
            webkitgtk_6_0
            gtk3
            glib
            gdk-pixbuf
            cairo
            pango
          ];

          dontBuild = true;
          dontConfigure = true;

          installPhase = ''
            mkdir -p $out/bin
            cp build/bin/parental-controls $out/bin/
            chmod +x $out/bin/parental-controls
          '';

          meta = with pkgs.lib; {
            description = "Parental Controls application built with Wails";
            homepage = "https://github.com/edmund/parental-controls";
            license = licenses.mit;
            maintainers = [ ];
            platforms = platforms.linux;
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            webkitgtk_6_0
            gtk3
            wails
            gcc
            nodejs_24
          ];

          shellHook = ''
          '';
        };
      }
    );
}
