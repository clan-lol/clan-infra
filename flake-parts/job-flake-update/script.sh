#!/usr/bin/env bash
set -euo pipefail

# prevent these variables from being unset by writePureShellScript
export KEEP_VARS="PR_TITLE REMOTE_BRANCH REPO REPO_DIR"

# configure variables for actions
export PR_TITLE="Automatic flake update - $(date --iso-8601=minutes)"
export REMOTE_BRANCH="flake-update-$(date --iso-8601)"
export REPO=gitea@git.clan.lol:clan/clan-infra.git
export REPO_DIR=$TMPDIR/repo

action-checkout
cd $REPO_DIR
action-flake-update
action-create-pr
