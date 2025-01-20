{
  config,
  pkgs,
  lib,
  ...
}:
let
  base_ipv4 = "23.88.17.207";
  base_ipv6 = "2a01:4f8:2220:1565::1";
in
{
  terraform.required_providers.external.source = "hashicorp/external";
  terraform.required_providers.hetznerdns.source = "timohirt/hetznerdns";

  data.external.hetznerdns-token = {
    program = [
      (lib.getExe (
        pkgs.writeShellApplication {
          name = "get-clan-secret";
          text = ''
            jq -n --arg secret "$(clan secrets get hetznerdns-token)" '{"secret":$secret}'
          '';
        }
      ))
    ];
  };

  provider.hetznerdns.apitoken = config.data.external.hetznerdns-token "result.secret";

  resource.hetznerdns_zone.clan_lol = {
    name = "clan.lol";
    ttl = 3600;
  };

  resource.hetznerdns_record.root_a = {
    zone_id = config.resource.hetznerdns_zone.clan_lol "id";
    name = "@";
    type = "A";
    value = base_ipv4;
  };

  resource.hetznerdns_record.root_aaaa = {
    zone_id = config.resource.hetznerdns_zone.clan_lol "id";
    name = "@";
    type = "AAAA";
    value = base_ipv6;
  };

  resource.hetznerdns_record.wildcard_a = {
    zone_id = config.resource.hetznerdns_zone.clan_lol "id";
    name = "*";
    type = "A";
    value = base_ipv4;
  };

  resource.hetznerdns_record.wildcard_aaaa = {
    zone_id = config.resource.hetznerdns_zone.clan_lol "id";
    name = "*";
    type = "AAAA";
    value = base_ipv6;
  };

  # for sending emails
  resource.hetznerdns_record.spf = {
    zone_id = config.resource.hetznerdns_zone.clan_lol "id";
    name = "@";
    type = "TXT";
    value = "\"v=spf1 ip4:${base_ipv4} ip6:${base_ipv6} ~all\"";
  };

  resource.hetznerdns_record.dkim = {
    zone_id = config.resource.hetznerdns_zone.clan_lol "id";
    name = "mail._domainkey";
    type = "TXT";
    # take from `systemctl status opendkim`
    value = "\"v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCdw2gyAg5TW2/OO2u8sbzlI6vfLkPycr4ufpfFQVvpd31hb6ctvpWXlzVHUDi9KyaWRydB7cAmYvPuZ7KFi1XPzQ213vy0S0AEbnXOJsTyT5FR8cmiuHPhiWGSMrSlB/l78kG6xK6A1x2lWCm2r7z/dzkLyCgAqI79YaUTcYO0eQIDAQAB\"";
  };

  resource.hetznerdns_record.adsp = {
    zone_id = config.resource.hetznerdns_zone.clan_lol "id";
    name = "_adsp._hostnamekey";
    type = "TXT";
    value = "\"dkim=all;\"";
  };

  resource.hetznerdns_record.matrix = {
    zone_id = config.resource.hetznerdns_zone.clan_lol "id";
    name = "_matrix._tcp";
    type = "SRV";
    value = "0 5 443 matrix";
  };

  resource.hetznerdns_record.dmarc = {
    zone_id = config.resource.hetznerdns_zone.clan_lol "id";
    name = "_dmarc";
    type = "TXT";
    value = "\"v=DMARC1; p=none; adkim=r; aspf=r; rua=mailto:joerc.dmarc@thalheim.io; ruf=mailto:joerg.dmarc@thalheim.io; pct=100\"";
  };
}
