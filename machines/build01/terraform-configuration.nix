{ config, ... }:

{
  terraform.required_providers.local.source = "hashicorp/local";

  resource.null_resource.install-build01 = {
    provisioner.local-exec = {
      command = "clan machines install build01 --update-hardware-config nixos-facter --target-host root@157.90.137.201 -i '${config.resource.local_sensitive_file.ssh_deploy_key "filename"}' --yes --debug";
    };
  };
}
