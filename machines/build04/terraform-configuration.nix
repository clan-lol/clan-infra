{ lib, ... }:
{
  resource.hcloud_zone_rrset.build04_a = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "build04";
    type = "A";
    records = [ { value = "49.12.162.14"; } ];
  };

  resource.hcloud_zone_rrset.build04_aaaa = {
    zone = lib.tf.ref "module.dns.clan_lol_zone_name";
    name = "build04";
    type = "AAAA";
    records = [ { value = "2a01:4f8:d1:570e::2"; } ];
  };
}
