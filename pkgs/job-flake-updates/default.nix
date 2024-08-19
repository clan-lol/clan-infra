{
  action-flake-update-pr-clan,
  action-flake-update-pr-clan-individual,
  writePureShellScriptBin,
}:
let
  job-flake-update =
    repo:
    writePureShellScriptBin "job-flake-update-${repo}" [ action-flake-update-pr-clan ] ''
      export REPO="gitea@git.clan.lol:clan/${repo}.git"
      export KEEP_VARS="REPO''${KEEP_VARS:+ $KEEP_VARS}"

      action-flake-update-pr-clan
    '';
  job-flake-update-individual =
    repo:
    writePureShellScriptBin "job-flake-update-${repo}-individual"
      [ action-flake-update-pr-clan-individual ]
      ''
        export REPO="gitea@git.clan.lol:clan/${repo}.git"
        export KEEP_VARS="REPO''${KEEP_VARS:+ $KEEP_VARS}"

        action-flake-update-pr-clan-individual
      '';
in
{
  job-flake-update-clan-core = job-flake-update "clan-core";
  job-flake-update-clan-core-individual = job-flake-update-individual "clan-core";
  job-flake-update-clan-homepage = job-flake-update "clan-homepage";
  job-flake-update-clan-infra = job-flake-update "clan-infra";
  job-flake-update-data-mesher = job-flake-update "data-mesher";
}
