{ lib, ... }:

{
  import = [
    { to = "hcloud_zone_rrset.build-x86-01_a"; id = "clan.lol/build-x86-01/A"; }
    { to = "hcloud_zone_rrset.build-x86-01_aaaa"; id = "clan.lol/build-x86-01/AAAA"; }
  ];

  resource.hcloud_zone_rrset.build-x86-01_a = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "build-x86-01";
    type = "A";
    records = [ { value = "144.76.97.38"; } ];
  };

  resource.hcloud_zone_rrset.build-x86-01_aaaa = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "build-x86-01";
    type = "AAAA";
    records = [ { value = "2a01:4f8:192:3223::2"; } ];
  };
}
