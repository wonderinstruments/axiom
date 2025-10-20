{
  pkgs,
  ...
}:
{
  # Install Python with all packages in a proper environment
  environment.systemPackages = [
    (pkgs.python313.withPackages (
      ps: with ps; [
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
      ]
    ))
  ];

  # Create python alias to python3
  environment.shellAliases = {
    python = "python3";
  };
}
