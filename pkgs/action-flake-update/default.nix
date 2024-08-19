{
  bash,
  coreutils,
  git,
  nix,
  writePureShellScriptBin,
}:
writePureShellScriptBin "action-flake-update"
  [
    bash
    coreutils
    git
    nix
  ]
  ''
    bash ${./script.sh} "$@"
  ''
