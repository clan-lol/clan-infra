{ self }:
{ lib, ... }:

{
  resource.storinator01_vpn_aaaa = {
    zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
    name = "storinator01.vpn";
    type = "AAAA";
    inherit
      (self.nixosConfigurations.storinator01.config.clan.core.vars.generators.zerotier.files.zerotier-ip)
      value
      ;
  };
}
