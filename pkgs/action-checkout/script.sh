#!/usr/bin/env bash
set -euo pipefail

# load BRANCH variable with default
BRANCH=${BRANCH:-main}

# load REPO_DIR variable with default
export REPO_DIR=${REPO_DIR:-.}

git clone --depth 1 --branch $BRANCH $REPO $REPO_DIR
