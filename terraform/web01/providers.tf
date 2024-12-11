terraform {
  required_providers {
    local      = { source = "hashicorp/local" }
    hetznerdns = { source = "timohirt/hetznerdns" }
  }
}

variable "hetznerdns_token" {}
provider "hetznerdns" {
  apitoken = var.hetznerdns_token
}
