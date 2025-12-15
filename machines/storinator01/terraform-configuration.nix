{ self }:
{ lib, ... }:

{
  resource.hcloud_zone_rrset.storinator01_vpn_aaaa = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "storinator01.vpn";
    type = "AAAA";
    records = [
      {
        inherit
          (self.nixosConfigurations.storinator01.config.clan.core.vars.generators.zerotier.files.zerotier-ip)
          value
          ;
      }
    ];
  };
}
