locals {
}

module "deploy" {
  source                 = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
  nixos_system_attr      = ".#nixosConfigurations.web01.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.web01.config.system.build.diskoScript"
  target_host            = var.ipv4_address
  instance_id            = "web01"
  debug_logging          = true
  extra_files_script     = "${path.module}/decrypt-ssh-secrets.sh"
  disk_encryption_key_scripts = [{
    path   = "/tmp/secret.key"
    script = "${path.module}/decrypt-zfs-key.sh"
  }]
}

locals {
  nixos_vars = {
    ipv6_address = var.ipv6_address
  }
}
