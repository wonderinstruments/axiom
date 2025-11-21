{ ... }:
{
  axiom.screensaver = {
    enable = true;
    sleepAfterMinutes = 10;

    # Choose your screensaver command:
    # Default: cmatrix (the Matrix rain effect)
    command = "cmatrix -a -b";

    # Or use the fractal zoom screensaver:
    # command = "python $HOME/scripts/fractal_saver.py";

    # Or aquarium:
    # command = "asciiquarium";

    # Or customize cmatrix:
    # command = "cmatrix -C cyan";  # Different color
    # command = "cmatrix -a -b -u 2";  # Slower speed
  };
}
