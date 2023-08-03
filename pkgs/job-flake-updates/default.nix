{ action-flake-update-pr-clan
, writePureShellScriptBin
}:
let
  job-flake-update = repo: writePureShellScriptBin "job-flake-update-${repo}" [ action-flake-update-pr-clan ] ''
    export REPO="gitea@git.clan.lol:clan/${repo}.git"
    export KEEP_VARS="REPO''${KEEP_VARS:+ $KEEP_VARS}"

    action-flake-update-pr-clan
  '';
in
{
  job-flake-update-clan-core = job-flake-update "clan-core";
  job-flake-update-clan-homepage = job-flake-update "clan-homepage";
  job-flake-update-clan-infra = job-flake-update "clan-infra";
}
