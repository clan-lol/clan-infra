#!/usr/bin/env bash
set -euo pipefail

REMOTE_BRANCH="${REMOTE_BRANCH:-auto-pr}"
PR_TITLE="${PR_TITLE:-'This PR was created automatically'}"

git diff --quiet || {
  echo -e "\e[31mWorking tree is dirty, please commit first\e[0m"
  git status
  exit 1
}

git push origin "HEAD:$REMOTE_BRANCH"

tea pr create "$@" \
  --head "$REMOTE_BRANCH" \
  --title "$PR_TITLE"
