#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils sops openssh
# shellcheck shell=bash

# shellcheck disable=SC1008,SC1128

set -euox pipefail

HOST="jitsi.clan.lol"

while ! ping -W 1 -c 1 "$HOST"; do
  sleep 1
done
while ! timeout --foreground 10 ssh -p 2222 "root@$HOST" true; do
  sleep 1
done

# Ensure that /run/partitioning-secrets/zfs/key only ever exists with the full key
clan vars get jitsi01 zfs/key | ssh -p 2222 "root@${HOST}" "mkdir -p /run/partitioning-secrets/zfs && cat > /run/partitioning-secrets/zfs/key.tmp && mv /run/partitioning-secrets/zfs/key.tmp /run/partitioning-secrets/zfs/key"
