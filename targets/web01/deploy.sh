#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix jq bash rsync

# shellcheck disable=SC1008,SC1128

set -euo pipefail

clan machines update web01
