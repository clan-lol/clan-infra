#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix jq bash rsync

set -euo pipefail

clan machines update web01
