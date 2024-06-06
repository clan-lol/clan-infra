resource "hetznerdns_zone" "server" {
  name = var.dns_zone
  ttl  = 3600
}

resource "hetznerdns_record" "root_a" {
  zone_id  = hetznerdns_zone.server.id
  name     = "@"
  type     = "A"
  value    = var.ipv4_address
}

resource "hetznerdns_record" "root_aaaa" {
  zone_id  = hetznerdns_zone.server.id
  name     = "@"
  type     = "AAAA"
  value    = var.ipv6_address
}

resource "hetznerdns_record" "wildcard_a" {
  zone_id  = hetznerdns_zone.server.id
  name     = "*"
  type     = "A"
  value    = var.ipv4_address
}

resource "hetznerdns_record" "wildcard_aaaa" {
  zone_id  = hetznerdns_zone.server.id
  name     = "*"
  type     = "AAAA"
  value    = var.ipv6_address
}

# for sending emails
resource "hetznerdns_record" "spf" {
  zone_id = hetznerdns_zone.server.id
  name    = "@"
  type    = "TXT"
  value   = "\"v=spf1 ip4:${var.ipv4_address} ip6:${var.ipv6_address} ~all\""
}

resource "hetznerdns_record" "dkim" {
  zone_id = hetznerdns_zone.server.id
  name    = "mail._domainkey"
  type    = "TXT"
  # take from `systemctl status opendkim`
  value = "\"v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCdw2gyAg5TW2/OO2u8sbzlI6vfLkPycr4ufpfFQVvpd31hb6ctvpWXlzVHUDi9KyaWRydB7cAmYvPuZ7KFi1XPzQ213vy0S0AEbnXOJsTyT5FR8cmiuHPhiWGSMrSlB/l78kG6xK6A1x2lWCm2r7z/dzkLyCgAqI79YaUTcYO0eQIDAQAB\""
}

resource "hetznerdns_record" "adsp" {
  zone_id = hetznerdns_zone.server.id
  name    = "_adsp._hostnamekey"
  type    = "TXT"
  value   = "\"dkim=all;\""
}

resource "hetznerdns_record" "matrix" {
  zone_id = hetznerdns_zone.server.id
  name    = "_matrix._tcp"
  type    = "SRV"
  value   = "0 5 443 matrix"
}

resource "hetznerdns_record" "dmarc" {
  zone_id = hetznerdns_zone.server.id
  name    = "_dmarc"
  type    = "TXT"
  value   = "\"v=DMARC1; p=none; adkim=r; aspf=r; rua=mailto:joerc.dmarc@thalheim.io; ruf=mailto:joerg.dmarc@thalheim.io; pct=100\""
}
