#!/usr/bin/env bash
set -euo pipefail

if [ "$(tea login list -o simple | wc -l)" -gt 0 ]; then
  exit 0
fi

GITEA_TOKEN="${GITEA_TOKEN:-"$(cat "$GITEA_TOKEN_FILE")"}"

tea login add \
  --token $GITEA_TOKEN \
  --url $GITEA_URL
