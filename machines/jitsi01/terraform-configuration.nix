{
  config,
  lib,
  ...
}:

{
  terraform.required_providers.local.source = "hashicorp/local";
  terraform.required_providers.hetznerdns.source = "timohirt/hetznerdns";

  resource.vultr_instance.jitsi01 = {
    label = "jitsi01";
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

  resource.hetznerdns_record.jitsi_a = {
    zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
    name = "jitsi";
    type = "A";
    value = config.resource.vultr_instance.jitsi01 "main_ip";
  };

  resource.hetznerdns_record.jitsi_aaaa = {
    zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
    name = "jitsi";
    type = "AAAA";
    value = config.resource.vultr_instance.jitsi01 "v6_main_ip";
  };

  resource.hetznerdns_record.jitsi01_a = {
    zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
    name = "jitsi01";
    type = "A";
    value = config.resource.vultr_instance.jitsi01 "main_ip";
  };

  resource.hetznerdns_record.jitsi01_aaaa = {
    zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
    name = "jitsi01";
    type = "AAAA";
    value = config.resource.vultr_instance.jitsi01 "v6_main_ip";
  };

  resource.hetznerdns_record.mumble_a = {
    zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
    name = "mumble";
    type = "A";
    value = config.resource.vultr_instance.jitsi01 "main_ip";
  };

  resource.hetznerdns_record.mumble_aaaa = {
    zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
    name = "mumble";
    type = "AAAA";
    value = config.resource.vultr_instance.jitsi01 "v6_main_ip";
  };

  resource.hetznerdns_record.meet_a = {
    zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
    name = "meet";
    type = "A";
    value = config.resource.vultr_instance.jitsi01 "main_ip";
  };

  resource.hetznerdns_record.meet_aaaa = {
    zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
    name = "meet";
    type = "AAAA";
    value = config.resource.vultr_instance.jitsi01 "v6_main_ip";
  };

  resource.null_resource.install-jitsi01 = {
    triggers = {
      instance_id = config.resource.vultr_instance.jitsi01 "id";
    };
    provisioner.local-exec = {
      command = "clan machines install jitsi01 --update-hardware-config nixos-facter --target-host root@${config.resource.vultr_instance.jitsi01 "main_ip"} -i '${config.resource.local_sensitive_file.ssh_deploy_key "filename"}' --yes";
    };
  };
}
