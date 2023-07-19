#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils sops openssh

set -euox pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <host>"
  exit 1
fi

HOST=$1
temp=$(mktemp -d)
trap 'rm -rf $temp' EXIT
sops --extract '["cryptsetup_key"]' -d secrets.yaml > "$temp/secret.key"

while ! ping -4 -W 1 -c 1 "$HOST"; do
  sleep 1
done
while ! timeout 4 ssh -p 2222 "root@$HOST" true; do
  sleep 1
done

ssh -p 2222 "root@$HOST" "cat > /crypt-ramfs/passphrase" < "$temp/secret.key"
