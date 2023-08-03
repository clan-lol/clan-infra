#!/usr/bin/env bash
set -euo pipefail

# prevent these variables from being unset by writePureShellScript
export KEEP_VARS="GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL GITEA_URL GITEA_USER PR_TITLE REMOTE_BRANCH REPO_DIR${KEEP_VARS:+ $KEEP_VARS}"

# configure variables for actions
export PR_TITLE="Automatic flake update - $(date --iso-8601=minutes)"
export REMOTE_BRANCH="flake-update-$(date --iso-8601)"
export REPO_DIR=$TMPDIR/repo
export GIT_AUTHOR_NAME="Clan Merge Bot"
export GIT_AUTHOR_EMAIL="clan-bot@git.clan.lol"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_NAME"
export GITEA_USER="clan-bot"
export GITEA_URL="https://git.clan.lol"

action-checkout
cd $REPO_DIR
action-ensure-tea-login
action-flake-update
action-create-pr --assignees clan-bot
