{ config, lib, ... }:

{
  terraform.required_providers.tls.source = "hashicorp/tls";

  resource.tls_private_key.ssh_deploy_key = {
    algorithm = "ED25519";
  };

  resource.local_sensitive_file.ssh_deploy_key = {
    filename = "${lib.tf.ref "path.module"}/.terraform-deploy-key";
    file_permission = "600";
    content = config.resource.tls_private_key.ssh_deploy_key "private_key_openssh";
  };

  resource.vultr_ssh_key.enzime = {
    name = "Enzime";
    ssh_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKZfejb9htpSB5K9p0RuEowErkba2BMKaze93ZVkQIE";
  };

  resource.vultr_ssh_key.terraform = {
    name = "clan-infra Terraform";
    ssh_key = config.resource.tls_private_key.ssh_deploy_key "public_key_openssh";
  };
}
