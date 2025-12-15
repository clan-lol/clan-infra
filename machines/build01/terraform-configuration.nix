{ self }:
{ config, lib, ... }:

{
  terraform.required_providers.local.source = "hashicorp/local";

  resource.hcloud_zone_rrset.build01_a = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "build01";
    type = "A";
    records = [ { value = "157.90.137.201"; } ];
  };

  resource.hcloud_zone_rrset.build01_aaaa = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "build01";
    type = "AAAA";
    records = [ { value = "2a01:4f8:2220:140f::1"; } ];
  };

  resource.hcloud_zone_rrset.build01_vpn_aaaa = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "build01.vpn";
    type = "AAAA";
    records = [
      {
        inherit
          (self.nixosConfigurations.build01.config.clan.core.vars.generators.zerotier.files.zerotier-ip)
          value
          ;
      }
    ];
  };

  resource.null_resource.install-build01 = {
    provisioner.local-exec = {
      command = "clan machines install build01 --update-hardware-config nixos-facter --target-host root@${lib.tf.ref "one(hcloud_zone_rrset.build01_a.records).value"} -i '${config.resource.local_sensitive_file.ssh_deploy_key "filename"}' --yes --debug";
    };
  };
}
