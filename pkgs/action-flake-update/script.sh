#!/usr/bin/env bash
set -euo pipefail

COMMIT_MSG="update flake lock - $(date --iso-8601=minutes)"

nix --experimental-features "nix-command flakes" \
  flake update --commit-lock-file --commit-lockfile-summary "$COMMIT_MSG"
