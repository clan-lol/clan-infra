#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils sops openssh nix

# shellcheck disable=SC1008,SC1128
set -euox pipefail

if [[ -z "${HOST:-}" ]]; then
  echo "HOST is not set"
  exit 1
fi
if [[ -z "${FLAKE_ATTR:-}" ]]; then
  echo "FLAKE_ATTR is not set"
  exit 1
fi
if [[ -z "${SOPS_SECRETS_FILE:-}" ]]; then
  echo "SOPS_SECRETS_FILE is not set"
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
  sops --extract '["'$keyname'"]' -d "$SOPS_SECRETS_FILE" > "$tmp/etc/ssh/$keyname"
done

umask 0177
sops --extract '["initrd_ssh_key"]' -d "$SOPS_SECRETS_FILE" > "$tmp/var/lib/secrets/initrd_ssh_key"
# restore umask
umask 0022

ssh "root@$HOST" "modprobe dm-raid && modprobe dm-integrity"

nix run --refresh github:numtide/nixos-anywhere -- \
   --debug \
   --disk-encryption-keys /tmp/secret.key <(sops --extract '["cryptsetup_key"]' --decrypt "$SOPS_SECRETS_FILE") \
   --extra-files "$tmp" \
   --flake "$FLAKE_ATTR" \
   "root@$HOST"
