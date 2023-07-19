terraform {
  backend "local" {}
}

variable "hetznerdns_token" {}

module "web01" {
  source            = "../../terraform/web01-new"
  hostname          = "new.clan.lol"
  dns_zone          = "new.clan.lol"
  nixos_flake_attr  = ".#web01-new"
  nixos_vars_file   = "${path.module}/nixos-vars.json"
  hetznerdns_token  = var.hetznerdns_token
  ipv4_address      = "65.109.103.5"
  ipv6_address      = "2a01:4f9:3080:282a::1"
  sops_secrets_file = "${abspath(path.module)}/secrets.yaml"
  tags = {
    Terraform = "true"
    Target    = "web01-new"
  }
}
