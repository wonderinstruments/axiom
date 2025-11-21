{ pkgs, ... }:
{
  axiom.screensaver = {
    enable = true;
    sleepAfterMinutes = 10;

    # Choose your screensaver command:
    # Default: cmatrix
    command = "${pkgs.cmatrix}/bin/cmatrix -a -b";

    # Or use the fractal zoom screensaver:
    # command = "python $HOME/scripts/fractal_saver.py";

    # Or any other terminal program:
    # command = "${pkgs.cmatrix}/bin/cmatrix -C cyan";
    # command = "${pkgs.asciiquarium}/bin/asciiquarium";
  };
}
