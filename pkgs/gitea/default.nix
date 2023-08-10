{ gitea }:

gitea.overrideAttrs (old: rec {
  patches = old.patches ++ [
    ./0001-add-bot-check.patch
  ];
})
