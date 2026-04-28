{ gitea, fetchpatch }:

gitea.overrideAttrs (old: {
  patches = old.patches ++ [
    ./0001-add-bot-check.patch

    (fetchpatch {
      name = "fix-automerge-accepting-disallowed-merge-styles.patch";
      url = "https://github.com/Enzime/gitea/commit/1df9c4582d7c9732e7f894cc07a7b70d4b6487f9.patch";
      hash = "sha256-Wmw4jCr8121Julp5vYL+owcwmopxCNbj/4IhGHQ6lSk=";
    })
  ];
})
