locals {
  hostnames = [
    "@",
    "git",
    "mail",
    "cache",
    "matrix",
    "www",
    "docs",
    "metrics"
  ]
}

resource "hetznerdns_zone" "server" {
  name = var.dns_zone
  ttl  = 3600
}

resource "hetznerdns_record" "server_a" {
  for_each = toset(local.hostnames)
  zone_id  = hetznerdns_zone.server.id
  name     = each.value
  type     = "A"
  value    = var.ipv4_address
}

resource "hetznerdns_record" "server_aaaa" {
  for_each = toset(local.hostnames)
  zone_id  = hetznerdns_zone.server.id
  name     = each.value
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
  name    = "v1._hostnamekey"
  type    = "TXT"
  # take from `systemctl status opendkim`
  value = "\"v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDpQeJirqh8VFGHRQBemqF5CeicC/5qHJn3vqKkVIOQNqkgp7IE+EZDg+MXoxMQZEJ0RbO0JpZZgYpOf3jf8o5w56WbE4dbpbi+9112R57k5w41R16Q0EUjf7MbrLJqcF6mtf+3bPklF9ngdcWhgN024YfhR9SlebCOapCVYqVt8QIDAQAB\""
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
