{ self }:
{ config, ... }:
let
  base_ipv4 = "23.88.17.207";
  base_ipv6 = "2a01:4f8:2220:1565::1";
in
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
      value =
        self.nixosConfigurations.storinator01.config.clan.core.vars.generators.zerotier.files.zerotier-ip.value;
    };

    build01 = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "build01.vpn";
      type = "AAAA";
      value =
        self.nixosConfigurations.build01.config.clan.core.vars.generators.zerotier.files.zerotier-ip.value;
    };

    build02 = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "build02.vpn";
      type = "A";
      value = "100.98.54.8";
    };

    root_a = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "@";
      type = "A";
      value = base_ipv4;
    };

    root_aaaa = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "@";
      type = "AAAA";
      value = base_ipv6;
    };

    wildcard_a = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "*";
      type = "A";
      value = base_ipv4;
    };

    wildcard_aaaa = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "*";
      type = "AAAA";
      value = base_ipv6;
    };

    # for sending emails
    spf = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "@";
      type = "TXT";
      value = "\"v=spf1 ip4:${base_ipv4} ip6:${base_ipv6} ~all\"";
    };

    dkim = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "mail._domainkey";
      type = "TXT";
      # take from `systemctl status opendkim`
      value = "\"v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCdw2gyAg5TW2/OO2u8sbzlI6vfLkPycr4ufpfFQVvpd31hb6ctvpWXlzVHUDi9KyaWRydB7cAmYvPuZ7KFi1XPzQ213vy0S0AEbnXOJsTyT5FR8cmiuHPhiWGSMrSlB/l78kG6xK6A1x2lWCm2r7z/dzkLyCgAqI79YaUTcYO0eQIDAQAB\"";
    };

    adsp = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "_adsp._hostnamekey";
      type = "TXT";
      value = "\"dkim=all;\"";
    };

    matrix = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "_matrix._tcp";
      type = "SRV";
      value = "0 5 443 matrix";
    };

    dmarc = {
      zone_id = config.resource.hetznerdns_zone.clan_lol "id";
      name = "_dmarc";
      type = "TXT";
      value = "\"v=DMARC1; p=none; adkim=r; aspf=r; rua=mailto:joerc.dmarc@thalheim.io; ruf=mailto:joerg.dmarc@thalheim.io; pct=100\"";
    };
  };

  output.clan_lol_zone_id = {
    value = config.resource.hetznerdns_zone.clan_lol "id";
  };

  output.thecomputer_co_zone_id = {
    value = config.resource.hetznerdns_zone.thecomputer_co "id";
  };
}
