{
  pkgs,
  ...
}:
let
  # Build the axiom Python package
  axiom = pkgs.python313.pkgs.buildPythonPackage {
    pname = "axiom";
    version = "0.1.0";
    format = "pyproject";

    src = ../axiom;

    nativeBuildInputs = with pkgs.python313.pkgs; [
      setuptools
      wheel
    ];
  };
in
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

        # fun
        pyfiglet
        term-image

        # axiom library
        axiom
      ]
    ))
    pkgs.python3 # Add python3 package so 'python' command is available
  ];
}
