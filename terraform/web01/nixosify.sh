#!/bin/sh

# shellcheck disable=SC1091

set -eu

installNix() {
  if ! command -v nix >/dev/null; then
    echo "Installing Nix..."
    trap 'rm -f /tmp/nix-install' EXIT
    if command -v curl; then
      curl -L https://nixos.org/nix/install >/tmp/nix-install
    elif command -v wget; then
      wget -O /tmp/nix-install https://nixos.org/nix/install
    else
      echo "Please install curl or wget"
      exit 1
    fi
    sh /tmp/nix-install --daemon --yes
  fi
  set +u
  . /etc/profile
  set -u
}

patchOsRelease() {
  cat >/etc/os-release <<EOF
ID=nixos
VARIANT_ID=installer
EOF
}

installTools() {
  env=$(
    cat <<EOF
with import <nixpkgs> {}; 
buildEnv { 
  name = "install-tools"; 
  paths = [ 
    nix 
    nixos-install-tools 
    parted 
    mdadm 
    xfsprogs 
    dosfstools 
    btrfs-progs 
    e2fsprogs 
    jq 
    util-linux 
  ];
}
EOF
  )
  tools=$(nix-build --no-out-link -E "$env")

  # check if /usr/local/bin is in PATH
  if ! echo "$PATH" | grep -q /usr/local/bin; then
    echo "WARNING: /usr/local/bin is not in PATH" >&2
  fi

  mkdir -p /usr/local/bin
  for i in "$tools/bin/"*; do
    ln -sf "$i" /usr/local/bin
  done
}

applyHetznerZfsQuirk() {
  if test -f /etc/hetzner-build; then
    # Hetzner has dummy binaries here for zfs,
    # however those won't work and even crashed the system.
    rm -f /usr/local/sbin/zfs /usr/local/sbin/zpool /usr/local/sbin/zdb
  fi
}

installNix
patchOsRelease
installTools
applyHetznerZfsQuirk
