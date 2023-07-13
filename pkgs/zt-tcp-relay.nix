{ lib
, rustPlatform
, fetchFromGitHub
, fetchpatch
}:

rustPlatform.buildRustPackage {
  pname = "zt-tcp-relay";
  version = "unstable-2022-08-02";

  src = fetchFromGitHub {
    owner = "alexander-akhmetov";
    repo = "zt-tcp-relay";
    rev = "2d4541d77807d57d5c303a1babfabf7f445e3946";
    hash = "sha256-6CkVvBRMsyAPBdkDBM1REJjM+3vs+ws/qCmQOfFInMw=";
  };

  patches = [
    # https://github.com/alexander-akhmetov/zt-tcp-relay/pull/19
    (fetchpatch {
      url = "https://github.com/alexander-akhmetov/zt-tcp-relay/commit/69f0a4f1f210dcd7a305036d4737d9a29215824d.patch";
      hash = "sha256-kqZS9IjwEggLE6CQFaacL2TyTUn0PQCz1TPdoZdDrk0=";
    })
  ];

  cargoHash = "sha256-MDygbJRi1aT4hfI7b2hwhYJ4UJyR1DehDAHDgbDZ35g=";

  meta = {
    description = "ZeroTier One TCP relay";
    homepage = "https://github.com/alexander-akhmetov/zt-tcp-relay";
  };
}
