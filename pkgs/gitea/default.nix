{ gitea, fetchpatch }:

gitea.overrideAttrs (old: {
  patches = old.patches ++ [
    ./0001-add-bot-check.patch

    (fetchpatch {
      name = "show-when-only-optional-checks-failed.patch";
      url = "https://github.com/go-gitea/gitea/commit/5420dc634781712c31f45ffca672cc221604f756.patch";
      hash = "sha256-ZEv2B8lalTv/paroyONavCuzv2M1vM1Xn2MWZw5vieA=";
    })
  ];
})
