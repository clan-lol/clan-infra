#!/usr/bin/env bash
set -euo pipefail

rm -f .terraform.lock.hcl
TFSTATE=$(mktemp)
if [[ -f "terraform.tfstate.sops" ]]; then
  sops -d terraform.tfstate.sops > "$TFSTATE"
fi
toplevel=$(git rev-parse --show-toplevel)
backupdir=$toplevel/.git/terraform/$(basename "$(dirname "$0")")
cleanup() {
  sops -e "$TFSTATE" > terraform.tfstate.sops && rm -f "$TFSTATE"
}
trap "cleanup" EXIT
terraform init -backup="$backupdir" -state-out="$TFSTATE"
terraform apply -backup="$backupdir" -state-out="$TFSTATE"
