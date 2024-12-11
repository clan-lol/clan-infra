#!/usr/bin/env bash
set -euo pipefail

rm -f .terraform.lock.hcl
if grep -q .sops terraform.tfstate; then
  sops -i -d terraform.tfstate
fi
if [[ -f secrets.auto.tfvars.sops.json ]]; then
  sops -d secrets.auto.tfvars.sops.json > secrets.auto.tfvars.json
fi
cleanup() {
  rm -f secrets.auto.tfvars.json
  sops -i -e terraform.tfstate
}

trap "cleanup" EXIT
tofu init
tofu "$@"
