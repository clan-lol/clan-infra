terraform {
  required_providers {
    hcloud     = { source = "hetznercloud/hcloud" }
    local      = { source = "hashicorp/local" }
    hetznerdns = { source = "timohirt/hetznerdns" }
  }
}

variable "hetznerdns_token" {}
provider "hetznerdns" {
  apitoken = var.hetznerdns_token
}
