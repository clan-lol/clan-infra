{ config, lib, ... }:

{
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

  resource.vultr_instance.jitsi01 = {
    label = "jitsi01";
    region = "sgp";
    plan = "vc2-2c-2gb";
    # Debian 12
    os_id = 2136;
    enable_ipv6 = true;
    ssh_key_ids = [
      (config.resource.vultr_ssh_key.terraform "id")
      (config.resource.vultr_ssh_key.enzime "id")
    ];
    backups = "disabled";
  };

  resource.hetznerdns_zone.clan_lol = {
    name = "clan.lol";
    ttl = 3600;
  };

  # TODO: terraform import hetznerdns_zone.clan_lol <id from web01>

  resource.hetznerdns_record.jitsi_a = {
    zone_id = config.resource.hetznerdns_zone.clan_lol "id";
    name = "jitsi";
    type = "A";
    value = config.resource.vultr_instance.jitsi01 "main_ip";
  };

  resource.hetznerdns_record.jitsi_aaaa = {
    zone_id = config.resource.hetznerdns_zone.clan_lol "id";
    name = "jitsi";
    type = "AAAA";
    value = config.resource.vultr_instance.jitsi01 "v6_main_ip";
  };

  resource.null_resource.nixos-remote = {
    triggers = {
      instance_id = null;
    };
    provisioner.local-exec = {
      command = "clan machines install jitsi01 --update-hardware-config nixos-facter --target-host root@${config.resource.vultr_instance.jitsi01 "main_ip"} -i '${config.resource.local_sensitive_file.ssh_deploy_key "filename"}' --yes";
    };
  };
}
