{ config, ... }:

{
  resource.tls_private_key.ssh_deploy_key = {
    algorithm = "ED25519";
  };

  resource.vultr_ssh_key.terraform = {
    name = "clan-infra Terraform";
    ssh_key = config.resource.tls_private_key.ssh_deploy_key "public_key_openssh";
  };

  resource.vultr_instance.jitsi01 = {
    label = "jitsi01";
    region = "sgp";
    plan = "vc2-2c-2gb";
    # Debian 12
    os_id = 2136;
    enable_ipv6 = true;
    ssh_key_ids = [ (config.resource.vultr_ssh_key.terraform "id") ];
    backups = "disabled";
  };

  resource.null_resource.nixos-remote = {
    triggers = {
      instance_id = null;
    };
    provisioner.local-exec = {
      command = "clan machines install jitsi01 --update-hardware-config nixos-facter --target-host root@${config.resource.vultr_instance.jitsi01 "main_ip"} --yes";
    };
  };
}
