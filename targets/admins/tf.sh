#!/usr/bin/env bash
set -euo pipefail

rm -f .terraform.lock.hcl
if grep -q .sops terraform.tfstate; then
  sops -i -d terraform.tfstate
  if [[ -f secrets.auto.tfvars.json ]]; then
    sops -d secrets.auto.tfvars.json > secrets.auto.tfvars
    exit 1
  fi
fi
cleanup() {
  sops -i -e terraform.tfstate
  rm -f secrets.auto.tfvars
}

trap "cleanup" EXIT
terraform init
terraform "$@"
