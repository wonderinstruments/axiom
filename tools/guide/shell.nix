{
  pkgs ? import <nixpkgs> { config.allowUnfree = true; },
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.go
    pkgs.cmake
    pkgs.gcc
    pkgs.pkg-config
    pkgs.openblas
    pkgs.git
    pkgs.gnumake
  ];

  shellHook = '''';
}
