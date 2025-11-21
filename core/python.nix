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

  # Build pynoise from GitLab
  pynoise = pkgs.python313.pkgs.buildPythonPackage {
    pname = "pynoise";
    version = "3.0.0";
    format = "setuptools";

    src = pkgs.fetchgit {
      url = "https://gitlab.com/atrus6/pynoise.git";
      rev = "a51f2f908b969596bbbebd005ab9b0c5950385f8";
      sha256 = "sha256-2w1FmlbDcx66J90KoS4JG50NlLgwoRm+fMVg1qRaYRc=";
    };

    propagatedBuildInputs = with pkgs.python313.pkgs; [
      sortedcontainers
      pillow
      numpy
      pyopencl
    ];

    # Skip tests if they fail
    doCheck = false;
  };

  # Build p5 from GitHub
  p5 = pkgs.python313.pkgs.buildPythonPackage {
    pname = "p5";
    version = "0.8.3";
    format = "setuptools";

    src = pkgs.fetchgit {
      url = "https://github.com/p5py/p5.git";
      rev = "fcff5096be20ee610dccf95193427b9e6661e2c1";
      sha256 = "sha256-GKEfrxdwRQ4bGHe+r1ep1Ks4qWfdA4oBorutMFaek9Y=";
    };

    propagatedBuildInputs = with pkgs.python313.pkgs; [
      glfw
      numpy
      pillow
      vispy
      pyopengl
      pyopengl-accelerate
      requests
      skia-pathops
    ];

    # Skip tests if they fail
    doCheck = false;
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

        # custom packages
        pynoise
        p5
      ]
    ))
    pkgs.python3 # Add python3 package so 'python' command is available
  ];
}
