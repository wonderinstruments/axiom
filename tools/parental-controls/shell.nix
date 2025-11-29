{ pkgs ? import <nixpkgs> { config.allowUnfree = true; } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.go
    pkgs.webkitgtk_6_0
    pkgs.gtk3
    pkgs.wails
    pkgs.gcc
    pkgs.nodejs_24
  ];

  shellHook = ''
  '';
}
