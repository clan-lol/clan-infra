{
  bash,
  coreutils,
  git,
  tea,
  openssh,
  writePureShellScriptBin,
}:
writePureShellScriptBin "action-create-pr"
  [
    bash
    coreutils
    git
    tea
    openssh
  ]
  ''
    bash ${./script.sh} "$@"
  ''
