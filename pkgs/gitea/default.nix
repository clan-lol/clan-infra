{ gitea, fetchpatch }:

gitea.overrideAttrs (old: {
  patches = old.patches ++ [
    ./0001-add-bot-check.patch

    ./0002-fix-automerge-accepting-disallowed-merge-styles.patch

    (fetchpatch {
      name = "make-merge-style-optional.patch";
      url = "https://github.com/go-gitea/gitea/commit/d8f62001fd1a82e5f77b4194e756329e079d11db.patch";
      hash = "sha256-7ZbIENUo/1HzOUoLqgF0HjespEbO3k/GlouMiE7Rx7w=";
      excludes = [ "templates/swagger/**" ];
    })
  ];
})
