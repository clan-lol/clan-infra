#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix jq bash rsync

set -euo pipefail

path=$(nix flake metadata --json '.#' | jq -r .path)
ip=65.109.103.5
rsync --checksum -vaF --delete -e ssh "${path}/" "root@${ip}:/etc/nixos"

ssh "root@$ip" nixos-rebuild switch \
    --fast \
    --option keep-going true \
    --option accept-flake-config true \
    --flake '/etc/nixos#web01'
