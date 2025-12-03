{ self }:
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

  resource.hetznerdns_record = {
    storinator01 = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "storinator01.vpn";
      type = "AAAA";
      inherit
        (self.nixosConfigurations.storinator01.config.clan.core.vars.generators.zerotier.files.zerotier-ip)
        value
        ;
    };

    build01 = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "build01.vpn";
      type = "AAAA";
      inherit
        (self.nixosConfigurations.build01.config.clan.core.vars.generators.zerotier.files.zerotier-ip)
        value
        ;
    };

    build01-v4 = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "build01";
      type = "A";
      value = "157.90.137.201";
    };

    build01-v6 = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "build01";
      type = "AAAA";
      value = "2a01:4f8:2220:140f::1";
    };

    build02 = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "build02.vpn";
      type = "A";
      value = "100.98.54.8";
    };
  };

  output.clan_lol_zone_id = {
    value = config.resource.hetznerdns_zone.clan_lol "id";
  };

  output.thecomputer_co_zone_id = {
    value = config.resource.hetznerdns_zone.thecomputer_co "id";
  };
}
