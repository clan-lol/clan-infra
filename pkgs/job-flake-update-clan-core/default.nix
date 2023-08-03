{ bash
, action-flake-update-pr-clan
, writePureShellScriptBin
}:
writePureShellScriptBin "job-flake-update-clan-core" [ bash action-flake-update-pr-clan ] ''
  bash ${./script.sh}
''
