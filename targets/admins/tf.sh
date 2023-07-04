#!/usr/bin/env bash
set -euo pipefail

rm -f .terraform.lock.hcl
if grep -q .sops terraform.tfstate; then
  sops -i -d terraform.tfstate || true
fi
cleanup() {
  sops -i -e terraform.tfstate
}
trap "cleanup" EXIT
terraform init
terraform "$@"
