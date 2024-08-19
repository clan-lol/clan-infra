{
  bash,
  coreutils,
  git,
  openssh,
  action-ensure-tea-login,
  action-create-pr,
  action-flake-update,
  writePureShellScriptBin,
}:
writePureShellScriptBin "action-flake-update-pr-clan-individual"
  [
    bash
    coreutils
    git
    openssh
    action-ensure-tea-login
    action-create-pr
    action-flake-update
  ]
  ''
    bash ${./script.sh}
  ''
