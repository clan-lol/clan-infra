{ config, ... }:
{
  resource.hetznerdns_record.build02_vpn_a = {
    zone_id = config.resource.hetznerdns_zone.clan_lol "id";
    name = "build02.vpn";
    type = "A";
    value = "100.98.54.8";
  };
}
