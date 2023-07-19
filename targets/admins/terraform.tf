terraform {
  backend "local" {
  }
}

# do we still need this module when leaving hcloud?
module "admin" {
  source   = "../../terraform/admins"
  ssh_keys = jsondecode(file("${path.module}/users.json"))
}
