{ gitea }:

gitea.overrideAttrs (old: {
  patches = old.patches ++ [
    ./0001-add-bot-check.patch
    ./0001-Add-an-immutable-tarball-link-to-archive-download-he.patch
  ];
})
