{
  lib,
  ...
}:
let
  base_ipv4 = "23.88.17.207";
  base_ipv6 = "2a01:4f8:2220:1565::1";
in
{
  terraform.required_providers.hetznerdns.source = "timohirt/hetznerdns";

  resource.hetznerdns_record = {
    root_a = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "@";
      type = "A";
      value = base_ipv4;
    };

    root_aaaa = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "@";
      type = "AAAA";
      value = base_ipv6;
    };

    wildcard_a = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "*";
      type = "A";
      value = base_ipv4;
    };

    wildcard_aaaa = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "*";
      type = "AAAA";
      value = base_ipv6;
    };

    web01_a = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "web01";
      type = "A";
      value = base_ipv4;
    };

    web01_aaaa = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "web01";
      type = "AAAA";
      value = base_ipv6;
    };

    mail_a = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "mail";
      type = "A";
      value = base_ipv4;
    };

    mail_aaaa = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "mail";
      type = "AAAA";
      value = base_ipv6;
    };

    mx = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "@";
      type = "MX";
      value = "10 mail.clan.lol.";
    };

    pass_a = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "pass";
      type = "A";
      value = base_ipv4;
    };

    pass_aaaa = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "pass";
      type = "AAAA";
      value = base_ipv6;
    };

    nextcloud_a = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "nextcloud";
      type = "A";
      value = base_ipv4;
    };

    nextcloud_aaaa = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "nextcloud";
      type = "AAAA";
      value = base_ipv6;
    };

    # for sending emails
    spf = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "@";
      type = "TXT";
      value = "\"v=spf1 ip4:${base_ipv4} ip6:${base_ipv6} ~all\"";
    };

    dkim = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "mail._domainkey";
      type = "TXT";
      # take from `systemctl status opendkim`
      value = "\"v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCdw2gyAg5TW2/OO2u8sbzlI6vfLkPycr4ufpfFQVvpd31hb6ctvpWXlzVHUDi9KyaWRydB7cAmYvPuZ7KFi1XPzQ213vy0S0AEbnXOJsTyT5FR8cmiuHPhiWGSMrSlB/l78kG6xK6A1x2lWCm2r7z/dzkLyCgAqI79YaUTcYO0eQIDAQAB\"";
    };

    adsp = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "_adsp._hostnamekey";
      type = "TXT";
      value = "\"dkim=all;\"";
    };

    matrix = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "_matrix._tcp";
      type = "SRV";
      value = "0 5 443 matrix";
    };

    dmarc = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "_dmarc";
      type = "TXT";
      value = "\"v=DMARC1; p=none; adkim=r; aspf=r; rua=mailto:joerc.dmarc@thalheim.io; ruf=mailto:joerg.dmarc@thalheim.io; pct=100\"";
    };

    # RFC 6186 service records for mail services
    imap = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "_imap._tcp";
      type = "SRV";
      value = "10 20 143 mail.clan.lol.";
    };

    imaps = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "_imaps._tcp";
      type = "SRV";
      value = "0 1 993 mail.clan.lol.";
    };

    pop3 = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "_pop3._tcp";
      type = "SRV";
      value = "0 1 110 mail.clan.lol.";
    };

    # Don't advertise Opportunistic TLS (STARTTLS) as it is insecure
    submission = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "_submission._tcp";
      type = "SRV";
      value = "0 0 0 .";
    };

    # Advertise SMTPS
    submissions = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "_submissions._tcp";
      type = "SRV";
      value = "0 1 465 mail.clan.lol.";
    };

    # Fastly CDN for cache2.clan.lol
    cache2 = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "cache2";
      type = "CNAME";
      value = "x.sni.global.fastly.net.";
    };

    # Fastly ACME challenge for cache2.clan.lol
    cache2_acme_challenge = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "_acme-challenge.cache2";
      type = "CNAME";
      value = "90idichjxpxvxf1cod.fastly-validations.com.";
    };

    # Fastly CDN for cache.clan.lol
    cache = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "cache";
      type = "CNAME";
      value = "x.sni.global.fastly.net.";
    };

    # Fastly ACME challenge for cache.clan.lol
    cache_acme_challenge = {
      zone_id = lib.tf.ref "module.dns.clan_lol_zone_id";
      name = "_acme-challenge.cache";
      type = "CNAME";
      value = "61s5zcfes5290tjs5r.fastly-validations.com.";
    };
  };
}
