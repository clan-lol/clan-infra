{ config, ... }:
{
  resource.hcloud_zone.clan_lol = {
    name = "clan.lol";
    mode = "primary";
  };

  resource.hcloud_zone.thecomputer_co = {
    name = "thecomputer.co";
    mode = "primary";
  };

  output.clan_lol_zone_name = {
    value = config.resource.hcloud_zone.clan_lol "name";
  };

  output.thecomputer_co_zone_name = {
    value = config.resource.hcloud_zone.thecomputer_co "name";
  };
}
