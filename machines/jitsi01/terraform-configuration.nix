{
  config,
  lib,
  ...
}:

{
  terraform.required_providers.local.source = "hashicorp/local";

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

  resource.hcloud_zone_rrset.jitsi_a = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "jitsi";
    type = "A";
    records = [ { value = config.resource.vultr_instance.jitsi01 "main_ip"; } ];
  };

  resource.hcloud_zone_rrset.jitsi_aaaa = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "jitsi";
    type = "AAAA";
    records = [
      {
        value = lib.tf.ref ''cidrhost("${config.resource.vultr_instance.jitsi01 "v6_main_ip"}/128", 0)'';
      }
    ];
  };

  resource.hcloud_zone_rrset.jitsi01_a = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "jitsi01";
    type = "A";
    records = [ { value = config.resource.vultr_instance.jitsi01 "main_ip"; } ];
  };

  resource.hcloud_zone_rrset.jitsi01_aaaa = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "jitsi01";
    type = "AAAA";
    records = [
      {
        value = lib.tf.ref ''cidrhost("${config.resource.vultr_instance.jitsi01 "v6_main_ip"}/128", 0)'';
      }
    ];
  };

  resource.hcloud_zone_rrset.meet_a = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "meet";
    type = "A";
    records = [ { value = config.resource.vultr_instance.jitsi01 "main_ip"; } ];
  };

  resource.hcloud_zone_rrset.meet_aaaa = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "meet";
    type = "AAAA";
    records = [
      {
        value = lib.tf.ref ''cidrhost("${config.resource.vultr_instance.jitsi01 "v6_main_ip"}/128", 0)'';
      }
    ];
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
