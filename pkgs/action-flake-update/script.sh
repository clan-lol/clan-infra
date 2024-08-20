#!/usr/bin/env bash
set -euo pipefail

NIX_VERSION=$(nix --version)
echo "Nix version: $NIX_VERSION"

if [ -z "${*}" ];then
COMMIT_MSG="update flake lock - $(date --iso-8601=minutes)"
nix --experimental-features "nix-command flakes" \
  flake update --commit-lock-file --commit-lockfile-summary "$COMMIT_MSG"
else
# Support for ancient nix versions
COMMIT_MSG="update flake lock - ${*} - $(date --iso-8601=minutes)"
nix --experimental-features "nix-command flakes" \
  flake lock --commit-lock-file --commit-lockfile-summary "$COMMIT_MSG" --update-input "${@}"
fi
