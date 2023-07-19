locals {
}

resource "null_resource" "nixos-anywhere" {
  triggers = {
    instance_id = var.ipv4_address
  }
  connection {
    type = "ssh"
    user = "root"
    host = var.ipv4_address
  }
  provisioner "remote-exec" {
    # needed because kexec is broken
    # https://github.com/numtide/nixos-anywhere/issues/136
    script = "${path.module}/nixosify.sh"
  }
  provisioner "local-exec" {
    environment = {
      HOST              = var.ipv4_address
      FLAKE_ATTR        = var.nixos_flake_attr
      SOPS_SECRETS_FILE = var.sops_secrets_file
    }
    command = "bash -x ${path.module}/install.sh"
  }
}

locals {
  nixos_vars = {
    ipv6_address = var.ipv6_address
  }
}
