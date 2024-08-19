#!/usr/bin/env bash
set -euo pipefail

# prevent these variables from being unset by writePureShellScript
export KEEP_VARS="GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL GITEA_URL GITEA_USER PR_TITLE REMOTE_BRANCH REPO_DIR${KEEP_VARS:+ $KEEP_VARS}"

# configure variables for actions
today=$(date --iso-8601)
today_minutes=$(date --iso-8601=minutes)
export REPO_DIR=$TMPDIR/repo
export GIT_AUTHOR_NAME="Clan Merge Bot"
export GIT_AUTHOR_EMAIL="clan-bot@git.clan.lol"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_NAME"
export GITEA_USER="clan-bot"
export GITEA_URL="https://git.clan.lol"


git clone --depth 1 --branch main "$REPO" "$REPO_DIR"
cd "$REPO_DIR"

inputs=$(nix flake metadata --json | jq '.locks.nodes | keys[]' | grep -v "root")

for input in $inputs;
do
	git checkout main
	export PR_TITLE="Automatic flake update - ${input} - ${today_minutes}"
	export REMOTE_BRANCH="flake-update-${input}-${today}"
	action-ensure-tea-login
	action-flake-update "$input"
	action-create-pr --assignees clan-bot
done

