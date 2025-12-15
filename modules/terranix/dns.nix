{ config, ... }:
{
  resource.hetznerdns_zone.clan_lol = {
    name = "clan.lol";
    ttl = 3600;
  };

  resource.hetznerdns_zone.thecomputer_co = {
    name = "thecomputer.co";
    ttl = 3600;
  };

  output.clan_lol_zone_id = {
    value = config.resource.hetznerdns_zone.clan_lol "id";
  };

  output.thecomputer_co_zone_id = {
    value = config.resource.hetznerdns_zone.thecomputer_co "id";
  };
}
