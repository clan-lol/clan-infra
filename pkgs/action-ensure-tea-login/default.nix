{ bash
, coreutils
, tea
, writePureShellScriptBin
}:
writePureShellScriptBin "action-ensure-tea-login" [ bash coreutils tea ] ''
  bash ${./script.sh}
''
