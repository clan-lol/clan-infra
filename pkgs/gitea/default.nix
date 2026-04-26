{ gitea, fetchpatch }:

gitea.overrideAttrs (old: {
  patches = old.patches ++ [
    ./0001-add-bot-check.patch
    ./0001-actions-report-commit-status-for-pull_request_review.patch

    (fetchpatch {
      name = "show-when-only-optional-checks-failed.patch";
      url = "https://github.com/go-gitea/gitea/commit/5420dc634781712c31f45ffca672cc221604f756.patch";
      hash = "sha256-ZEv2B8lalTv/paroyONavCuzv2M1vM1Xn2MWZw5vieA=";
    })

    (fetchpatch {
      name = "fix-automerge-accepting-disallowed-merge-styles.patch";
      url = "https://github.com/Enzime/gitea/commit/1df9c4582d7c9732e7f894cc07a7b70d4b6487f9.patch";
      hash = "sha256-Wmw4jCr8121Julp5vYL+owcwmopxCNbj/4IhGHQ6lSk=";
    })
  ];
})
