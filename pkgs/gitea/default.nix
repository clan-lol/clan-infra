{ gitea, fetchpatch }:

gitea.overrideAttrs (old: {
  patches = old.patches ++ [
    ./0001-add-bot-check.patch

    # https://github.com/Enzime/gitea/tree/push-ylslosqvwwts
    (fetchpatch {
      name = "try-not-to-block-anything-that-breaks-nix.patch";
      url = "https://github.com/Enzime/gitea/commit/fda7b59413018c7ef4ac64d2f4dd1a896d1bee10.patch";
      hash = "sha256-+G0nqTuY6M4p8vWnFY2UNNu4gx0VGrnrXELcqYsIStI=";
    })

    (fetchpatch {
      name = "fix-automerge-accepting-disallowed-merge-styles.patch";
      url = "https://github.com/Enzime/gitea/commit/1df9c4582d7c9732e7f894cc07a7b70d4b6487f9.patch";
      hash = "sha256-Wmw4jCr8121Julp5vYL+owcwmopxCNbj/4IhGHQ6lSk=";
    })

    (fetchpatch {
      name = "make-merge-style-optional.patch";
      url = "https://github.com/go-gitea/gitea/commit/d8f62001fd1a82e5f77b4194e756329e079d11db.patch";
      hash = "sha256-7ZbIENUo/1HzOUoLqgF0HjespEbO3k/GlouMiE7Rx7w=";
      excludes = [ "templates/swagger/**" ];
    })
  ];
})
