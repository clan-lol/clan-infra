#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils sops openssh
# shellcheck shell=bash

# shellcheck disable=SC1008,SC1128

set -euox pipefail

HOST="23.88.17.207"

while ! ping -W 1 -c 1 "$HOST"; do
  sleep 1
done
while ! timeout --foreground 10 ssh -p 2222 "root@$HOST" true; do
  sleep 1
done

# Ensure that /tmp/secret.key only ever exists with the full key
clan secrets get zfs-key | ssh -p 2222 "root@${HOST}" "cat > /tmp/secret.key.tmp && mv /tmp/secret.key.tmp /tmp/secret.key"
