{ gitea, fetchurl }:

gitea.overrideAttrs (old: rec {
  name = "gitea-${version}";
  # we currently use a release candiate to generate runner tokes on startup
  version = "1.20.0-rc2";
  patches = old.patches ++ [
    ./0001-add-bot-check.patch
  ];

  # not fetching directly from the git repo, because that lacks several vendor files for the web UI
  src = fetchurl {
    url = "https://dl.gitea.com/gitea/${version}/gitea-src-${version}.tar.gz";
    hash = "sha256-AYlTbbYtd+N8W7buEd1+6J49mGE6X6a+1eYAcwEore4=";
  };
})
