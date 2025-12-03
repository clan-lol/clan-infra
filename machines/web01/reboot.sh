#!/usr/bin/env bash
set -ux

HOST="clan.lol"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "root@$HOST" reboot
# wait till shutdown
while ping -W 1 -c 1 "$HOST"; do
  sleep 1
done

exec "$SCRIPT_DIR/decrypt.sh"
