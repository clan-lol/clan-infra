{ bash
, action-flake-update-pr-clan
, writePureShellScriptBin
}:
writePureShellScriptBin "job-flake-update-clan-infra" [
  bash
  action-flake-update-pr-clan
] ''
  bash ${./script.sh}
''
