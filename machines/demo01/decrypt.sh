#!/usr/bin/env nix
#! nix shell --inputs-from ../.. nixpkgs#bash nixpkgs#coreutils nixpkgs#sops nixpkgs#openssh clan-core --command bash
# shellcheck shell=bash

# shellcheck disable=SC1008,SC1128

set -euox pipefail

HOST="demo.clan.lol"

while ! ping -W 1 -c 1 "$HOST"; do
  sleep 1
done
while ! timeout --foreground 10 ssh -p 2222 "root@$HOST" true; do
  sleep 1
done

# Ensure that /run/partitioning-secrets/zfs/key only ever exists with the full key
clan vars get demo01 zfs/key | ssh -p 2222 "root@${HOST}" "mkdir -p /run/partitioning-secrets/zfs && cat > /run/partitioning-secrets/zfs/key.tmp && mv /run/partitioning-secrets/zfs/key.tmp /run/partitioning-secrets/zfs/key"
