{ bash
, coreutils
, git
, openssh
, writePureShellScriptBin
}:
writePureShellScriptBin "action-checkout" [ bash coreutils git openssh ] ''
  bash ${./script.sh}
''
