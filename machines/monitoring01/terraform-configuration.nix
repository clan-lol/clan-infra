{
  config,
  lib,
  ...
}:

{
  terraform.required_providers.local.source = "hashicorp/local";

  resource.hcloud_ssh_key.enzime = {
    name = "Enzime";
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKZfejb9htpSB5K9p0RuEowErkba2BMKaze93ZVkQIE";
  };

  resource.hcloud_ssh_key.terraform = {
    name = "clan-infra Terraform";
    public_key = lib.tf.ref "trimspace(tls_private_key.ssh_deploy_key.public_key_openssh)";
  };

  resource.hcloud_server.monitoring01 = {
    name = "monitoring01";
    # 8 vCPU / 16 GB / 160 GB
    server_type = "cx43";
    location = "fsn1";
    image = "debian-13";
    ssh_keys = [
      (config.resource.hcloud_ssh_key.terraform "id")
      (config.resource.hcloud_ssh_key.enzime "id")
    ];
    public_net = {
      ipv4_enabled = true;
      ipv6_enabled = true;
    };
    backups = false;
  };

  resource.hcloud_zone_rrset.monitoring_a = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "monitoring";
    type = "A";
    records = [ { value = config.resource.hcloud_server.monitoring01 "ipv4_address"; } ];
  };

  resource.hcloud_zone_rrset.monitoring_aaaa = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "monitoring";
    type = "AAAA";
    records = [ { value = config.resource.hcloud_server.monitoring01 "ipv6_address"; } ];
  };

  resource.hcloud_zone_rrset.monitoring01_a = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "monitoring01";
    type = "A";
    records = [ { value = config.resource.hcloud_server.monitoring01 "ipv4_address"; } ];
  };

  resource.hcloud_zone_rrset.monitoring01_aaaa = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "monitoring01";
    type = "AAAA";
    records = [ { value = config.resource.hcloud_server.monitoring01 "ipv6_address"; } ];
  };

  resource.null_resource.install-monitoring01 = {
    triggers = {
      instance_id = config.resource.hcloud_server.monitoring01 "id";
    };
    provisioner.local-exec = {
      command = "clan machines install monitoring01 --update-hardware-config nixos-facter --target-host root@${config.resource.hcloud_server.monitoring01 "ipv4_address"} -i '${config.resource.local_sensitive_file.ssh_deploy_key "filename"}' --yes";
    };
  };
}
