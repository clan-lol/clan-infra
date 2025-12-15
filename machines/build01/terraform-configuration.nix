{ self }:
{ config, lib, ... }:

{
  terraform.required_providers.local.source = "hashicorp/local";

  resource.hetznerdns_record.build01_a = {
    zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
    name = "build01";
    type = "A";
    value = "157.90.137.201";
  };

  resource.hetznerdns_record.build01_aaaa = {
    zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
    name = "build01";
    type = "AAAA";
    value = "2a01:4f8:2220:140f::1";
  };

  resource.hetznerdns_record.build01_vpn_aaaa = {
    zone_id = config.resource.hetznerdns_zone.clan_lol "id";
    name = "build01.vpn";
    type = "AAAA";
    inherit
      (self.nixosConfigurations.build01.config.clan.core.vars.generators.zerotier.files.zerotier-ip)
      value
      ;
  };

  resource.null_resource.install-build01 = {
    provisioner.local-exec = {
      command = "clan machines install build01 --update-hardware-config nixos-facter --target-host root@${config.resource.hetznerdns_record.build01_a "value"} -i '${config.resource.local_sensitive_file.ssh_deploy_key "filename"}' --yes --debug";
    };
  };
}
