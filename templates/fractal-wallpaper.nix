{ ... }:
{
  axiom.fractal-wallpaper = {
    enable = true;
    width = 1920;
    height = 1080;
    fractalType = "mandelbrot"; # or "julia"
    iterations = 256; # Higher = more detail but slower
    searchDepth = 3; # Higher = more zoomed in (2-5 recommended)

    # For Julia set, customize these:
    # juliaCReal = -0.7;
    # juliaCImag = 0.27015;
  };
}
