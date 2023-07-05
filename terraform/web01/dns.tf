resource "netlify_dns_zone" "server" {
  site_id = ""
  name    = var.netlify_dns_zone
}

resource "netlify_dns_record" "server_a" {
  zone_id  = netlify_dns_zone.server.id
  hostname = var.domain
  type     = "A"
  value    = hcloud_server.server.ipv4_address
}

resource "netlify_dns_record" "server_aaaa" {
  zone_id  = netlify_dns_zone.server.id
  hostname = var.domain
  type     = "AAAA"
  value    = hcloud_server.server.ipv6_address
}

resource "netlify_dns_record" "www_a" {
  zone_id  = netlify_dns_zone.server.id
  hostname = "www.${var.domain}"
  type     = "A"
  value    = hcloud_server.server.ipv4_address
}

resource "netlify_dns_record" "www_aaaa" {
  zone_id  = netlify_dns_zone.server.id
  hostname = "www.${var.domain}"
  type     = "AAAA"
  value    = hcloud_server.server.ipv6_address
}

resource "netlify_dns_record" "git_a" {
  zone_id  = netlify_dns_zone.server.id
  hostname = "git.${var.domain}"
  type     = "A"
  value    = hcloud_server.server.ipv4_address
}

resource "netlify_dns_record" "git_aaaa" {
  zone_id  = netlify_dns_zone.server.id
  hostname = "git.${var.domain}"
  type     = "AAAA"
  value    = hcloud_server.server.ipv6_address
}

resource "netlify_dns_record" "mail_a" {
  zone_id  = netlify_dns_zone.server.id
  hostname = "mail.${var.domain}"
  type     = "A"
  value    = hcloud_server.server.ipv4_address
}

resource "netlify_dns_record" "mail_aaaa" {
  zone_id  = netlify_dns_zone.server.id
  hostname = "mail.${var.domain}"
  type     = "AAAA"
  value    = hcloud_server.server.ipv6_address
}

# for sending emails
resource "netlify_dns_record" "spf" {
  zone_id  = netlify_dns_zone.server.id
  hostname = var.domain
  type     = "TXT"
  value    = "v=spf1 ip4:${hcloud_server.server.ipv4_address} ip6:${hcloud_server.server.ipv6_address} ~all"
}

resource "netlify_dns_record" "dkim" {
  zone_id  = netlify_dns_zone.server.id
  hostname = "v1._domainkey.${var.domain}"
  type     = "TXT"
  # take from `systemctl status opendkim`
  value    = "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDTFSkQcM0v6mC4kiWEoF/EgK/hPVgOBJlHesLVIe+8BmidylaUowKlyC2gECipXhoVX9++OfMFAKNtGrIJcCTVNH/DRGkhbHLSxzzXijCbJ7G/fjpHRifpxMydEmybQDKdidR44YMR74Aj0OwUEgu+N/yJZ2+ubOlstW0fZJaJwQIDAQAB"
}

resource "netlify_dns_record" "adsp" {
  zone_id  = netlify_dns_zone.server.id
  hostname = "_adsp._domainkey.${var.domain}"
  type     = "TXT"
  value    = "dkim=all;"
}

resource "netlify_dns_record" "dmarc" {
  zone_id  = netlify_dns_zone.server.id
  hostname = "_dmarc.${var.domain}"
  type     = "TXT"
  value    = "v=DMARC1; p=none; adkim=r; aspf=r; rua=mailto:joerc.dmarc@thalheim.io; ruf=mailto:joerg.dmarc@thalheim.io; pct=100"
}

resource "hcloud_rdns" "master_a" {
  server_id  = hcloud_server.server.id
  ip_address = hcloud_server.server.ipv4_address
  dns_ptr    = "mail.${var.domain}"
}

resource "hcloud_rdns" "master_aaaa" {
  server_id  = hcloud_server.server.id
  ip_address = hcloud_server.server.ipv6_address
  dns_ptr    = "mail.${var.domain}"
}

#v1._domainkey        IN        TXT        ( "" )  ;

