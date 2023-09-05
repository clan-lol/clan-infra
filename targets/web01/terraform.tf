terraform {
  backend "local" {}
}

variable "hetznerdns_token" {}

module "web01" {
  source            = "../../terraform/web01"
  hostname          = "clan.lol"
  dns_zone          = "clan.lol"
  nixos_flake_attr  = ".#web01"
  nixos_vars_file   = "${path.module}/nixos-vars.json"
  hetznerdns_token  = var.hetznerdns_token
  ipv4_address      = "65.21.12.51"
  ipv6_address      = "2a01:4f9:3080:418b::1"
  sops_secrets_file = "${abspath(path.module)}/secrets.yaml"
  tags = {
    Terraform = "true"
    Target    = "web01"
  }
}
