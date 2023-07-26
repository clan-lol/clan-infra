#!/usr/bin/env bash
set -euo pipefail

# prevent these variables from being unset by writePureShellScript
export KEEP_VARS="GIT_AUTHOR_NAME GIT_COMMITTER_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_EMAIL PR_TITLE REMOTE_BRANCH REPO REPO_DIR"

# configure variables for actions
export PR_TITLE="Automatic flake update - $(date --iso-8601=minutes)"
export REMOTE_BRANCH="flake-update-$(date --iso-8601)"
export REPO="https://git.clan.lol/clan/clan-infra"
export REPO_DIR=$TMPDIR/repo

action-checkout
cd $REPO_DIR
action-flake-update
action-create-pr
