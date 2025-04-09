{
  buildPythonApplication,
  setuptools,
  matrix-nio,
  aiofiles,
  aiohttp,
  markdown2,
  git,
  tiktoken,
  ...
}:

let

  pythonDependencies = [
    matrix-nio
    aiofiles
    aiohttp
    markdown2
    tiktoken
  ];

  runtimeDependencies = [ git ];

  testDependencies = pythonDependencies ++ runtimeDependencies ++ [ ];
in
buildPythonApplication {
  name = "matrix-bot";
  src = ./.;
  format = "pyproject";

  nativeBuildInputs = [ setuptools ];

  propagatedBuildInputs = pythonDependencies ++ runtimeDependencies;

  passthru.testDependencies = testDependencies;

  # Clean up after the package to avoid leaking python packages into a devshell
  postFixup = ''
    rm $out/nix-support/propagated-build-inputs
  '';

  meta.mainProgram = "matrix-bot";
}
