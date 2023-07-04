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
