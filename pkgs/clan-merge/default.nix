{ pkgs ? import <nixpkgs> { }
, lib ? pkgs.lib
, python3 ? pkgs.python3
, ruff ? pkgs.ruff
, runCommand ? pkgs.runCommand
,
}:
let
  pyproject = builtins.fromTOML (builtins.readFile ./pyproject.toml);
  name = pyproject.project.name;

  src = lib.cleanSource ./.;

  dependencies = lib.attrValues {
    # inherit (python3.pkgs)
    #   some-package
    #   ;
  };

  devDependencies = lib.attrValues {
    inherit (pkgs) ruff;
    inherit (python3.pkgs)
      black
      mypy
      pytest
      pytest-cov
      setuptools
      wheel
      ;
  };

  package = python3.pkgs.buildPythonPackage {
    inherit name src;
    format = "pyproject";
    nativeBuildInputs = [
      python3.pkgs.setuptools
    ];
    propagatedBuildInputs =
      dependencies
      ++ [ ];
    passthru.tests = { inherit check; };
    passthru.devDependencies = devDependencies;
  };

  checkPython = python3.withPackages (_ps: devDependencies ++ dependencies);

  check = runCommand "${name}-check" { } ''
    cp -r ${src} ./src
    chmod +w -R ./src
    cd src
    export PYTHONPATH=.
    echo -e "\x1b[32m## run mypy\x1b[0m"
    ${checkPython}/bin/mypy .
    echo -e "\x1b[32m## run pytest\x1b[0m"
    ${checkPython}/bin/pytest
    touch $out
  '';

in
package
