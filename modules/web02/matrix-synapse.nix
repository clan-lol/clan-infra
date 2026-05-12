{ lib, ... }:
{
  # We host personal.computer elsewhere currently and use a SRV record
  # to point the Matrix server to this machine
  services.nginx.virtualHosts."personal.computer" = lib.mkForce { };

  clan.core.vars.generators.matrix-password-admin = {
    prompts.matrix-recovery-key-admin.persist = true;
    files.matrix-recovery-key-admin.deploy = false;
  };

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
  services.nginx.virtualHosts."matrix.personal.computer".extraConfig =
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
