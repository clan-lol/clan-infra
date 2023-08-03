{ bash
, action-flake-update-pr-clan
, writePureShellScriptBin
}:
writePureShellScriptBin "job-flake-update-clan-homepage" [
  bash
  action-flake-update-pr-clan
] ''
  bash ${./script.sh}
''
