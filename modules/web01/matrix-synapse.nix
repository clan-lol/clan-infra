{
  # Increase rate limits for Matrix bots
  services.matrix-synapse.settings = {
    max_upload_size = "150M";
    rc_login = {
      address = {
        per_second = 20;
        burst_count = 200;
      };
      account = {
        per_second = 20;
        burst_count = 200;
      };
      failed_attempts = {
        per_second = 3;
        burst_count = 15;
      };
    };
  };
  services.nginx.virtualHosts."matrix.clan.lol".extraConfig =
    let
      timeout = "10m";
    in
    ''
      keepalive_timeout ${timeout};
      send_timeout ${timeout};
      client_body_timeout ${timeout};
      client_header_timeout ${timeout};
      proxy_connect_timeout ${timeout};
      proxy_read_timeout ${timeout};
      proxy_send_timeout ${timeout};
    '';
}
