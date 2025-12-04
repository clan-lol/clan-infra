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

    build-x86-01-v4 = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "build-x86-01";
      type = "A";
      value = "144.76.97.38";
    };

    build-x86-01-v6 = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "build-x86-01";
      type = "AAAA";
      value = "2a01:4f8:192:3223::2";
    };

    build02 = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "build02.vpn";
      type = "A";
      value = "100.98.54.8";
    };

    # Root domain
    clan_lol_a = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "@";
      type = "A";
      value = "23.88.17.207";
    };
    clan_lol_aaaa = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "@";
      type = "AAAA";
      value = "2a01:4f8:2220:1565::1";
    };

    # Mail server
    mail_clan_lol_a = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "mail";
      type = "A";
      value = "23.88.17.207";
    };
    mail_clan_lol_aaaa = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "mail";
      type = "AAAA";
      value = "2a01:4f8:2220:1565::1";
    };

    # MX record
    clan_lol_mx = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "@";
      type = "MX";
      value = "10 mail.clan.lol.";
    };

    # SPF - only web01
    clan_lol_spf = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "@";
      type = "TXT";
      value = "v=spf1 ip4:23.88.17.207 ip6:2a01:4f8:2220:1565::1 ~all";
    };

    # DMARC
    clan_lol_dmarc = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "_dmarc";
      type = "TXT";
      value = "v=DMARC1; p=none; adkim=r; aspf=r; rua=mailto:joerg.dmarc@thalheim.io; ruf=mailto:joerg.dmarc@thalheim.io; pct=100";
    };

    # DKIM
    clan_lol_dkim = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "mail._domainkey";
      type = "TXT";
      value = "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCdw2gyAg5TW2/OO2u8sbzlI6vfLkPycr4ufpfFQVvpd31hb6ctvpWXlzVHUDi9KyaWRydB7cAmYvPuZ7KFi1XPzQ213vy0S0AEbnXOJsTyT5FR8cmiuHPhiWGSMrSlB/l78kG6xK6A1x2lWCm2r7z/dzkLyCgAqI79YaUTcYO0eQIDAQAB";
    };
  };

  output.clan_lol_zone_id = {
    value = config.resource.hetznerdns_zone.clan_lol "id";
  };

  output.thecomputer_co_zone_id = {
    value = config.resource.hetznerdns_zone.thecomputer_co "id";
  };
}
