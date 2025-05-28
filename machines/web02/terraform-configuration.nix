{
  config,
  lib,
  ...
}:

{
  terraform.required_providers.local.source = "hashicorp/local";
  terraform.required_providers.hetznerdns.source = "timohirt/hetznerdns";

  resource.vultr_instance.web02 = {
    label = "web02";
    region = "sgp";
    plan = "vc2-2c-4gb";
    # Debian 12
    os_id = 2136;
    enable_ipv6 = true;
    ssh_key_ids = [
      (config.resource.vultr_ssh_key.terraform "id")
      (config.resource.vultr_ssh_key.enzime "id")
    ];
    backups = "disabled";
  };

  resource.hetznerdns_record.thecomputer_co_root_a = {
    zone_id = lib.tf.ref "module.dns.thecomputer_co_zone_id";
    name = "@";
    type = "A";
    value = config.resource.vultr_instance.web02 "main_ip";
  };

  resource.hetznerdns_record.thecomputer_co_root_aaaa = {
    zone_id = lib.tf.ref "module.dns.thecomputer_co_zone_id";
    name = "@";
    type = "AAAA";
    value = config.resource.vultr_instance.web02 "v6_main_ip";
  };

  resource.null_resource.install-web02 = {
    triggers = {
      instance_id = config.resource.vultr_instance.web02 "id";
    };
    provisioner.local-exec = {
      command = "clan machines install web02 --update-hardware-config nixos-facter --target-host root@${config.resource.vultr_instance.web02 "main_ip"} -i '${config.resource.local_sensitive_file.ssh_deploy_key "filename"}' --yes";
    };
  };
}
