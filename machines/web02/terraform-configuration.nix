{
  config,
  lib,
  ...
}:

{
  terraform.required_providers.local.source = "hashicorp/local";

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

  resource.hcloud_zone_rrset.thecomputer_co_root_a = {
    zone = lib.tf.ref "module.dns.thecomputer_co_zone_name";
    name = "@";
    type = "A";
    records = [ { value = config.resource.vultr_instance.web02 "main_ip"; } ];
  };

  resource.hcloud_zone_rrset.thecomputer_co_root_aaaa = {
    zone = lib.tf.ref "module.dns.thecomputer_co_zone_name";
    name = "@";
    type = "AAAA";
    records = [ { value = config.resource.vultr_instance.web02 "v6_main_ip"; } ];
  };

  resource.hcloud_zone_rrset.web02_a = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "web02";
    type = "A";
    records = [ { value = config.resource.vultr_instance.web02 "main_ip"; } ];
  };

  resource.hcloud_zone_rrset.web02_aaaa = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "web02";
    type = "AAAA";
    records = [ { value = config.resource.vultr_instance.web02 "v6_main_ip"; } ];
  };

  resource.hcloud_zone_rrset.thecomputer_co_outline_a = {
    zone = lib.tf.ref "module.dns.thecomputer_co_zone_name";
    name = "outline";
    type = "A";
    records = [ { value = config.resource.vultr_instance.web02 "main_ip"; } ];
  };

  resource.hcloud_zone_rrset.thecomputer_co_idm_a = {
    zone = lib.tf.ref "module.dns.thecomputer_co_zone_name";
    name = "idm";
    type = "A";
    records = [ { value = config.resource.vultr_instance.web02 "main_ip"; } ];
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
