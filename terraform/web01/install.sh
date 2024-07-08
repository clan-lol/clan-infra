#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils sops openssh nix

# shellcheck shell=bash
# shellcheck disable=SC1008,SC1128

if [[ -z "${HOST:-}" ]]; then
  echo "HOST is not set"
  exit 1
fi
if [[ -z "${FLAKE_ATTR:-}" ]]; then
  echo "FLAKE_ATTR is not set"
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf $tmp' EXIT


mkdir -p "$tmp/etc/ssh" "$tmp/var/lib/secrets"
for keyname in ssh_host_rsa_key ssh_host_rsa_key.pub ssh_host_ed25519_key ssh_host_ed25519_key.pub; do
  if [[ "$keyname" == *.pub ]]; then
    umask 0133
  else
    umask 0177
  fi
  clan secrets get "$keyname" > "$tmp/etc/ssh/$keyname"
done

umask 0177
clan secrets get "initrd_ssh_key" > "$tmp/var/lib/secrets/initrd_ssh_key"
# restore umask
umask 0022

ssh "root@$HOST" "modprobe dm-raid && modprobe dm-integrity"

nix run --refresh github:numtide/nixos-anywhere -- \
   --debug \
   --disk-encryption-keys /tmp/secret.key <(clan secrets get cryptsetup_key) \
   --extra-files "$tmp" \
   --flake "$FLAKE_ATTR" \
   "root@$HOST"
