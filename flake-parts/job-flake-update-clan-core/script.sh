#!/usr/bin/env bash
set -euo pipefail

export REPO="gitea@git.clan.lol:clan/clan-core.git"
export KEEP_VARS="REPO${KEEP_VARS:+ $KEEP_VARS}"

action-flake-update-pr-clan
