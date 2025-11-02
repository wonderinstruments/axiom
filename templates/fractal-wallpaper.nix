{ ... }:
{
  axiom.fractal-wallpaper = {
    enable = true;
    width = 1920;
    height = 1080;
    fractalType = "mandelbrot"; # or "julia"
    iterations = 100; # Higher = more detail but slower
    searchDepth = 4; # Higher = more zoomed in (2-5 recommended)
    regenerateOnRebuild = false; # Set to true to regenerate on every rebuild

    # For Julia set, customize these:
    # juliaCReal = -0.7;
    # juliaCImag = 0.27015;
  };
}
