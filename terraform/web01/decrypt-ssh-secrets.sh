#!/usr/bin/env bash

mkdir -p etc/ssh var/lib/secrets

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

umask 0177
(cd "$SCRIPT_DIR" && clan secrets get initrd_ssh_key) > ./var/lib/secrets/initrd_ssh_key

# restore umask
umask 0022

for keyname in ssh_host_rsa_key ssh_host_rsa_key.pub ssh_host_ed25519_key ssh_host_ed25519_key.pub; do
  if [[ $keyname == *.pub ]]; then
    umask 0133
  else
    umask 0177
  fi
  (cd "$SCRIPT_DIR" && clan secrets get "$keyname") >"./etc/ssh/$keyname"
done
