# Record the SSH public key into Hetzner Cloud
data "hcloud_ssh_keys" "server" {
  with_selector = "web01=true"
}

resource "hcloud_server" "server" {
  image       = "debian-10"
  keep_disk   = true
  name        = "web01"
  server_type = var.server_type
  ssh_keys    = data.hcloud_ssh_keys.server.ssh_keys.*.name
  backups     = false
  labels      = var.tags

  location = var.server_location

  lifecycle {
    # Don't destroy server instance if ssh keys changes.
    ignore_changes  = [ssh_keys]
    prevent_destroy = false
  }
}

module "deploy" {
  depends_on             = [local_file.nixos_vars]
  source                 = "github.com/numtide/nixos-anywhere//terraform/all-in-one"
  nixos_system_attr      = ".#nixosConfigurations.${var.nixos_flake_attr}.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.${var.nixos_flake_attr}.config.system.build.diskoNoDeps"
  target_host            = hcloud_server.server.ipv4_address
  instance_id            = hcloud_server.server.id
  debug_logging          = true
}

locals {
  nixos_vars = {
    ipv6_address = hcloud_server.server.ipv6_address
    ssh_keys     = data.hcloud_ssh_keys.server.ssh_keys.*.public_key
  }
}
