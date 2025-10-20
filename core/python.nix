{
  pkgs,
  ...
}:
{
  # Install Python with all packages
  environment.systemPackages = with pkgs.python3Packages; [
    # Specified packages from ansible
    i3ipc
    numpy
    pandas
    tqdm

    # Essential Python libraries
    python-dateutil
    jinja2
    click
    colorama

    # Development and debugging tools
    pydantic
    ipython
    pytest
    black
    flake8
    mypy

    # Data science essentials
    pillow
    matplotlib
    scipy
    scikit-learn
  ];
  environment.SystemPackages = [
    pkgs.python3 # Keep base python3 available
  ];

  home.shellAliases = {
    python = "python3";
  };
}
