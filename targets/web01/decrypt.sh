#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils sops openssh
# shellcheck shell=bash

# shellcheck disable=SC1008,SC1128

set -euox pipefail

HOST="clan.lol"

while ! ping -4 -W 1 -c 1 "$HOST"; do
  sleep 1
done
while ! timeout 4 ssh -p 2222 "root@$HOST" true; do
  sleep 1
done

clan secrets get zfs-key | ssh -p 2222 "root@${HOST}" "zpool import -f -a; cat > /tmp/secret.key && zfs load-key -a && touch /tmp/decrypted"
