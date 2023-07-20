#!/usr/bin/env bash


HOST=clan.lol
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ssh "root@$HOST" reboot
# wait till shutdown
while ping -4 -W 1 -c 1 "$HOST"; do
  sleep 1
done

"$SCRIPT_DIR/decrypt.sh"
