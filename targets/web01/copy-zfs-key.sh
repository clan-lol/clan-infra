#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils sops openssh
# shellcheck shell=bash

# shellcheck disable=SC1008,SC1128

set -euox pipefail

HOST="23.88.17.207"

clan secrets get zfs-key | ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "root@${HOST}" "cat > /tmp/secret.key && zfs load-key -a"
