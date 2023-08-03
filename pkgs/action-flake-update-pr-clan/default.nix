{ bash
, coreutils
, action-checkout
, action-ensure-tea-login
, action-create-pr
, action-flake-update
, writePureShellScriptBin
}:
writePureShellScriptBin "action-flake-update-pr-clan" [
  bash
  coreutils
  action-checkout
  action-ensure-tea-login
  action-create-pr
  action-flake-update
] ''
  bash ${./script.sh}
''
