{
  lib,
  ...
}:
let
  base_ipv4 = "23.88.17.207";
  base_ipv6 = "2a01:4f8:2220:1565::1";
in
{
  import = [
    {
      to = "hcloud_zone_rrset.root_a";
      id = "clan.lol/@/A";
    }
    {
      to = "hcloud_zone_rrset.root_aaaa";
      id = "clan.lol/@/AAAA";
    }
    {
      to = "hcloud_zone_rrset.wildcard_a";
      id = "clan.lol/*/A";
    }
    {
      to = "hcloud_zone_rrset.wildcard_aaaa";
      id = "clan.lol/*/AAAA";
    }
    {
      to = "hcloud_zone_rrset.web01_a";
      id = "clan.lol/web01/A";
    }
    {
      to = "hcloud_zone_rrset.web01_aaaa";
      id = "clan.lol/web01/AAAA";
    }
    {
      to = "hcloud_zone_rrset.mail_a";
      id = "clan.lol/mail/A";
    }
    {
      to = "hcloud_zone_rrset.mail_aaaa";
      id = "clan.lol/mail/AAAA";
    }
    {
      to = "hcloud_zone_rrset.mx";
      id = "clan.lol/@/MX";
    }
    {
      to = "hcloud_zone_rrset.pass_a";
      id = "clan.lol/pass/A";
    }
    {
      to = "hcloud_zone_rrset.pass_aaaa";
      id = "clan.lol/pass/AAAA";
    }
    {
      to = "hcloud_zone_rrset.nextcloud_a";
      id = "clan.lol/nextcloud/A";
    }
    {
      to = "hcloud_zone_rrset.nextcloud_aaaa";
      id = "clan.lol/nextcloud/AAAA";
    }
    {
      to = "hcloud_zone_rrset.spf";
      id = "clan.lol/@/TXT";
    }
    {
      to = "hcloud_zone_rrset.dkim";
      id = "clan.lol/mail._domainkey/TXT";
    }
    {
      to = "hcloud_zone_rrset.adsp";
      id = "clan.lol/_adsp._hostnamekey/TXT";
    }
    {
      to = "hcloud_zone_rrset.matrix";
      id = "clan.lol/_matrix._tcp/SRV";
    }
    {
      to = "hcloud_zone_rrset.dmarc";
      id = "clan.lol/_dmarc/TXT";
    }
    {
      to = "hcloud_zone_rrset.imap";
      id = "clan.lol/_imap._tcp/SRV";
    }
    {
      to = "hcloud_zone_rrset.imaps";
      id = "clan.lol/_imaps._tcp/SRV";
    }
    {
      to = "hcloud_zone_rrset.pop3";
      id = "clan.lol/_pop3._tcp/SRV";
    }
    {
      to = "hcloud_zone_rrset.pop3s";
      id = "clan.lol/_pop3s._tcp/SRV";
    }
    {
      to = "hcloud_zone_rrset.submission";
      id = "clan.lol/_submission._tcp/SRV";
    }
    {
      to = "hcloud_zone_rrset.submissions";
      id = "clan.lol/_submissions._tcp/SRV";
    }
    {
      to = "hcloud_zone_rrset.cache2";
      id = "clan.lol/cache2/CNAME";
    }
    {
      to = "hcloud_zone_rrset.cache2_acme_challenge";
      id = "clan.lol/_acme-challenge.cache2/CNAME";
    }
    {
      to = "hcloud_zone_rrset.cache";
      id = "clan.lol/cache/CNAME";
    }
    {
      to = "hcloud_zone_rrset.cache_acme_challenge";
      id = "clan.lol/_acme-challenge.cache/CNAME";
    }
  ];

  resource.hcloud_zone_rrset = {
    root_a = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "@";
      type = "A";
      records = [ { value = base_ipv4; } ];
    };

    root_aaaa = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "@";
      type = "AAAA";
      records = [ { value = base_ipv6; } ];
    };

    wildcard_a = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "*";
      type = "A";
      records = [ { value = base_ipv4; } ];
    };

    wildcard_aaaa = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "*";
      type = "AAAA";
      records = [ { value = base_ipv6; } ];
    };

    web01_a = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "web01";
      type = "A";
      records = [ { value = base_ipv4; } ];
    };

    web01_aaaa = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "web01";
      type = "AAAA";
      records = [ { value = base_ipv6; } ];
    };

    mail_a = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "mail";
      type = "A";
      records = [ { value = base_ipv4; } ];
    };

    mail_aaaa = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "mail";
      type = "AAAA";
      records = [ { value = base_ipv6; } ];
    };

    mx = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "@";
      type = "MX";
      records = [ { value = "10 mail.clan.lol."; } ];
    };

    pass_a = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "pass";
      type = "A";
      records = [ { value = base_ipv4; } ];
    };

    pass_aaaa = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "pass";
      type = "AAAA";
      records = [ { value = base_ipv6; } ];
    };

    nextcloud_a = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "nextcloud";
      type = "A";
      records = [ { value = base_ipv4; } ];
    };

    nextcloud_aaaa = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "nextcloud";
      type = "AAAA";
      records = [ { value = base_ipv6; } ];
    };

    # for sending emails
    spf = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "@";
      type = "TXT";
      records = [
        {
          value = lib.tf.ref ''provider::hcloud::txt_record("v=spf1 ip4:${base_ipv4} ip6:${base_ipv6} ~all")'';
        }
      ];
    };

    dkim = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "mail._domainkey";
      type = "TXT";
      # taken from `systemctl status opendkim`
      records = [
        {
          value = lib.tf.ref ''provider::hcloud::txt_record("v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCdw2gyAg5TW2/OO2u8sbzlI6vfLkPycr4ufpfFQVvpd31hb6ctvpWXlzVHUDi9KyaWRydB7cAmYvPuZ7KFi1XPzQ213vy0S0AEbnXOJsTyT5FR8cmiuHPhiWGSMrSlB/l78kG6xK6A1x2lWCm2r7z/dzkLyCgAqI79YaUTcYO0eQIDAQAB")'';
        }
      ];
    };

    adsp = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "_adsp._hostnamekey";
      type = "TXT";
      records = [ { value = lib.tf.ref ''provider::hcloud::txt_record("dkim=all;")''; } ];
    };

    matrix = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "_matrix._tcp";
      type = "SRV";
      records = [ { value = "0 5 443 matrix.clan.lol."; } ];
    };

    dmarc = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "_dmarc";
      type = "TXT";
      records = [
        {
          value = lib.tf.ref ''provider::hcloud::txt_record("v=DMARC1; p=none; adkim=r; aspf=r; rua=mailto:joerg.dmarc@thalheim.io; ruf=mailto:joerg.dmarc@thalheim.io; pct=100")'';
        }
      ];
    };

    # RFC 6186 service records for mail services
    # Don't advertise Opportunistic TLS (STARTTLS) as it is insecure
    imap = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "_imap._tcp";
      type = "SRV";
      records = [ { value = "0 0 0 ."; } ];
    };

    imaps = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "_imaps._tcp";
      type = "SRV";
      records = [ { value = "0 1 993 mail.clan.lol."; } ];
    };

    # Don't advertise Opportunistic TLS (STARTTLS) as it is insecure
    pop3 = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "_pop3._tcp";
      type = "SRV";
      records = [ { value = "0 0 0 ."; } ];
    };

    pop3s = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "_pop3s._tcp";
      type = "SRV";
      records = [ { value = "0 1 995 mail.clan.lol."; } ];
    };

    # Don't advertise Opportunistic TLS (STARTTLS) as it is insecure
    submission = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "_submission._tcp";
      type = "SRV";
      records = [ { value = "0 0 0 ."; } ];
    };

    # Advertise SMTPS
    submissions = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "_submissions._tcp";
      type = "SRV";
      records = [ { value = "0 1 465 mail.clan.lol."; } ];
    };

    # Fastly CDN for cache2.clan.lol
    cache2 = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "cache2";
      type = "CNAME";
      records = [ { value = "x.sni.global.fastly.net."; } ];
    };

    # Fastly ACME challenge for cache2.clan.lol
    cache2_acme_challenge = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "_acme-challenge.cache2";
      type = "CNAME";
      records = [ { value = "90idichjxpxvxf1cod.fastly-validations.com."; } ];
    };

    # Fastly CDN for cache.clan.lol
    cache = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "cache";
      type = "CNAME";
      records = [ { value = "x.sni.global.fastly.net."; } ];
    };

    # Fastly ACME challenge for cache.clan.lol
    cache_acme_challenge = {
      zone = lib.tf.ref "module.dns.clan_lol_zone_name";
      name = "_acme-challenge.cache";
      type = "CNAME";
      records = [ { value = "61s5zcfes5290tjs5r.fastly-validations.com."; } ];
    };
  };
}
