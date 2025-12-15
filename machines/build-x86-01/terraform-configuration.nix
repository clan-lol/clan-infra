{ lib, ... }:

{
  resource.hetznerdns_record.build-x86-01_a = {
    zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
    name = "build-x86-01";
    type = "A";
    value = "144.76.97.38";
  };

  resource.hetznerdns_record.build-x86-01_aaaa = {
    zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
    name = "build-x86-01";
    type = "AAAA";
    value = "2a01:4f8:192:3223::2";
  };
}
