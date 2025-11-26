{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.musopen;

  musopen-setup = pkgs.stdenv.mkDerivation {
    name = "musopen-dvd";
    version = "1.0";

    src = pkgs.fetchurl {
      url = "https://archive.org/download/musopen-dvd/Musopen-DVD.zip";
      sha256 = "0v16y42a5vhqprg7h4s2qs0r9zg90y84bix3p9s4adp7r2ixjkrs";
    };

    nativeBuildInputs = [ pkgs.unzip ];

    unpackPhase = ''
      unzip $src
    '';

    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };

in
{
  options.axiom.musopen = {
    enable = lib.mkEnableOption "Musopen DVD setup";
  };

  config = lib.mkIf cfg.enable {
    # Configure XDG music directory
    xdg.userDirs = {
      enable = true;
      music = "${config.home.homeDirectory}/Music";
    };

    # Create the Music directory and symlink the Musopen content
    home.activation.setupMusopen = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/Music
      $DRY_RUN_CMD ln -sf ${musopen-setup}/* ${config.home.homeDirectory}/Music/
    '';
  };
}
