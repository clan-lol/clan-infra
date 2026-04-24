{
  lib,
  pkgs,
}:
pkgs.gitea-actions-runner.overrideAttrs (old: {
  # REMOVEME when gitea-actions-runner in nixpkgs is updated past 0.4.1 and should include these changes
  version =
    assert lib.versionOlder old.version "0.4.2";
    "0.5.0-unstable-2026-04-24";

  src = pkgs.fetchFromGitea {
    domain = "gitea.com";
    owner = "gitea";
    repo = "act_runner";
    rev = "fbd631692892212367ff9330f1b80019f8d0c72b";
    hash = "sha256-5wBGFL+doxCZ49i/eRAZ33Iq3fR2KzVh4ZGi3N0XhVo=";
  };

  patches = (old.patches or [ ]) ++ [
    # https://gitea.com/gitea/act_runner/pulls/846
    (pkgs.fetchpatch {
      url = "https://gitea.com/Enzime/act_runner/commit/0ad79f3190c57c2e1960cd5e796cc04369a2bd1a.patch";
      hash = "sha256-5LD4ylpaWQ8yfQVdEov4X6JATe3vq/PF0nGFCz6kyOI=";
    })
  ];

  vendorHash = "sha256-l+T8r2XjmP9gbnUZFoesrpfOn9e+vmAmRuUBoryB8Uk=";

  nativeCheckInputs = [ pkgs.git ];

  preCheck = ''
    export HOME=$(mktemp -d)
    git config --global user.email "test@test"
    git config --global user.name "Test"
  '';

  # Skip tests that require network access or Docker
  checkFlags = [
    "-skip=${
      lib.concatStringsSep "|" [
        # artifactcache: need network (outbound IP detection)
        "^TestHandler$"
        "^TestHandler_gcCache$"
        # artifacts: needs Docker
        "^TestArtifactFlow$"
        # common/git: needs network (clones from github.com)
        "^TestGitCloneExecutor$"
        # container: need Docker daemon
        "^TestImageExistsLocally$"
        "^TestDocker$"
        "^TestDockerExecAbort$"
        "^TestDockerExecFailure$"
        "^TestDockerCopyTarStream"
        "^TestCheckVolumes$"
        "^TestGetSocketAndHost"
        # runner: need network or Docker
        "^TestActionCache$"
        "^TestRunEvent$"
        "^TestRunEventHostEnvironment$"
        "^TestDryrunEvent$"
        "^TestDockerActionForcePullForceRebuild$"
        "^TestRunDifferentArchitecture$"
        "^TestMaskValues$"
        "^TestRunEventSecrets$"
        "^TestRunWithService$"
        "^TestRunActionInputs$"
        "^TestRunEventPullRequest$"
        "^TestRunMatrixWithUserDefinedInclusions$"
        "^TestJobExecutor$"
      ]
    }"
  ];
})
