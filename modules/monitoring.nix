{ config, ... }:
{
  imports = [ ./acme.nix ];

  # The clanService creates this vhost and infers useSSL from whether it has TLS.
  services.nginx.virtualHosts.${config.networking.fqdn} = {
    enableACME = true;
    forceSSL = true;
    # Grafana lives under /grafana/, so a bare / would serve nginx's default page.
    locations."= /".return = "302 /grafana/";
  };

  # Upstream sets instance_interface_names on every Mimir ring but the querier's,
  # which then probes the nonexistent [eth0 en0] default and crash loops.
  services.mimir.configuration.querier.ring.instance_addr = "127.0.0.1";

  # Mimir's blocks retention and Loki's compactor retention are both off by default.
  services.mimir.configuration.limits.compactor_blocks_retention_period = "180d";

  services.loki.configuration = {
    limits_config.retention_period = "90d";
    compactor = {
      working_directory = "${config.services.loki.dataDir}/compactor";
      retention_enabled = true;
      delete_request_store = "filesystem";
    };
  };
}
