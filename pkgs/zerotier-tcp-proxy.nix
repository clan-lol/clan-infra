{ stdenv, fetchFromGitHub, fetchpatch, zerotierProxyPort ? 443 }:
stdenv.mkDerivation {
  name = "zerotier-tcp-proxy";
  src = fetchFromGitHub {
    owner = "zerotier";
    repo = "ZeroTierOne";
    rev = "008a768f15763aa4b1c73434cdc517b6b4e3f997";
    hash = "sha256-BX589KbO+6eoyUo7UUDEL7pyIgpUE25deax+dmvGGG4=";
  };
  patches = [
    (fetchpatch {
      url = "https://github.com/zerotier/ZeroTierOne/commit/dd2006d494e85a41d8b818b37460e7cf458a2aee.patch";
      hash = "sha256-nuao04pDha7h62RHviUZYx21p6bNOyiU78kBBq2o2Rs=";
    })
  ];
  buildPhase = ''
    pushd tcp-proxy
    sed -i -e "s/ZT_TCP_PROXY_TCP_PORT.*443/ZT_TCP_PROXY_TCP_PORT ${toString zerotierProxyPort}/g" tcp-proxy.cpp
    cat tcp-proxy.cpp
    make -j $NIX_BUILD_CORES CXX=$CXX
    popd
  '';
  installPhase = ''
    install -D -m 755 tcp-proxy/tcp-proxy $out/bin/zerotier-tcp-proxy
  '';
}
