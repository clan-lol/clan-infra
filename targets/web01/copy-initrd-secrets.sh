#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils sops openssh
# shellcheck shell=bash

# shellcheck disable=SC1008,SC1128

set -euox pipefail

HOST="23.88.17.207"

clan secrets get initrd_ssh_key | ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "root@${HOST}" "mkdir -p /mnt/var/lib/secrets && cat > /mnt/var/lib/secrets/initrd_ssh_key && chmod 0600 /mnt/var/lib/secrets/initrd_ssh_key"
