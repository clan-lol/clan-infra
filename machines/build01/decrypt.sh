#!/usr/bin/env bash
# shellcheck disable=SC1008,SC1128
set -euxo pipefail

HOST="157.90.137.201"

while ! ping -W 1 -c 1 "$HOST"; do
  sleep 1
done
while ! timeout --foreground 10 ssh -p 2222 "root@$HOST" true; do
  sleep 1
done

clan vars get build01 luks/password | awk '1; END{print ""}' | ssh -p 2222 -tt "root@${HOST}" systemctl default
