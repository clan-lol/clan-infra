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
      name = "fix-automerge-permission-check.patch";
      url = "https://github.com/go-gitea/gitea/commit/08a02ec060e30b1337e25f534d045abd5f59e8d7.patch";
      hash = "sha256-+u3Ilwx+nY90v3VHaiQUqZJ1ok02ObvboiN5Y0wd+3A=";
    })
  ];
})
