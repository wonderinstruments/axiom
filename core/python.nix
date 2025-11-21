{
  pkgs,
  config,
  ...
}:
let
  # Build the axiom package with generated colors from Stylix
  axiom = pkgs.python313.pkgs.buildPythonPackage {
    pname = "axiom";
    version = "0.1.0";
    format = "pyproject";

    src = ../axiom;

    nativeBuildInputs = with pkgs.python313.pkgs; [
      setuptools
      wheel
    ];

    # Generate colors.py from template with Stylix colors
    postPatch = ''
      substituteInPlace colors.py.in \
        --replace "@base00@" "${config.lib.stylix.colors.base00}" \
        --replace "@base01@" "${config.lib.stylix.colors.base01}" \
        --replace "@base02@" "${config.lib.stylix.colors.base02}" \
        --replace "@base03@" "${config.lib.stylix.colors.base03}" \
        --replace "@base04@" "${config.lib.stylix.colors.base04}" \
        --replace "@base05@" "${config.lib.stylix.colors.base05}" \
        --replace "@base06@" "${config.lib.stylix.colors.base06}" \
        --replace "@base07@" "${config.lib.stylix.colors.base07}" \
        --replace "@base08@" "${config.lib.stylix.colors.base08}" \
        --replace "@base09@" "${config.lib.stylix.colors.base09}" \
        --replace "@base0A@" "${config.lib.stylix.colors.base0A}" \
        --replace "@base0B@" "${config.lib.stylix.colors.base0B}" \
        --replace "@base0C@" "${config.lib.stylix.colors.base0C}" \
        --replace "@base0D@" "${config.lib.stylix.colors.base0D}" \
        --replace "@base0E@" "${config.lib.stylix.colors.base0E}" \
        --replace "@base0F@" "${config.lib.stylix.colors.base0F}"
      mv colors.py.in colors.py
    '';
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
