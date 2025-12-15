{ lib, ... }:
{
  import = [
    { to = "hcloud_zone_rrset.build02_vpn_a"; id = "clan.lol/build02.vpn/A"; }
  ];

  resource.hcloud_zone_rrset.build02_vpn_a = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "build02.vpn";
    type = "A";
    records = [ { value = "100.98.54.8"; } ];
  };
}
