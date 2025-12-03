{ pkgs ? import <nixpkgs> { config.allowUnfree = true; } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.cargo
    pkgs.rustc
    pkgs.rust-analyzer
    pkgs.pkg-config
  ];

  shellHook = ''
  '';
}
