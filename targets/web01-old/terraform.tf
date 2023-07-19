terraform {
  backend "local" {}
}

variable "hetznerdns_token" {}

module "web01" {
  source           = "../../terraform/web01-old"
  domain           = "clan.lol"
  nixos_flake_attr = "web01-old"
  nixos_vars_file  = "${path.module}/nixos-vars.json"
  hetznerdns_token = var.hetznerdns_token
  tags = {
    Terraform = "true"
    Target    = "web01-old"
  }
}
