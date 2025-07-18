{ config, lib, ... }:

{
  terraform.required_providers.local.source = "hashicorp/local";

  resource.vultr_instance.demo01 = {
    label = "demo01";
    region = "sgp";
    plan = "vc2-2c-4gb";
    # Debian 12
    os_id = 2136;
    enable_ipv6 = true;
    ssh_key_ids = [
      (config.resource.vultr_ssh_key.terraform "id")
    ];
    backups = "disabled";
  };

  resource.hetznerdns_record.demo_a = {
    zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
    name = "demo";
    type = "A";
    value = config.resource.vultr_instance.demo01 "main_ip";
  };

  resource.null_resource.install-demo01 = {
    triggers = {
      instance_id = config.resource.vultr_instance.demo01 "id";
    };
    provisioner.local-exec = {
      command = "clan machines install demo01 --update-hardware-config nixos-facter --target-host root@${config.resource.vultr_instance.demo01 "main_ip"} -i '${config.resource.local_sensitive_file.ssh_deploy_key "filename"}' --yes --debug";
    };
  };
}
