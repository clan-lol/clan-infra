{ stdenv, lib, pkgs, ... }:

let
  domain = "metrics.gchq.icu";
in
{
  users.users.goaccess = {
    isSystemUser = true;
    group = "nginx";
    createHome = true;
    home = "/var/www/goaccess";
    homeMode = "0774";
  };

  services.nginx.commonHttpConfig = ''
    log_format vcombined '$host:$server_port $remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referrer" "$http_user_agent"';
    access_log /var/log/nginx/private.log vcombined;
  '';

  systemd.services.goaccess = {
    description = "GoAccess server monitoring";
    serviceConfig = {
      User = "goaccess";
      Group = "nginx";
      ExecStart = ''
        ${pkgs.goaccess}/bin/goaccess \
          -f /var/log/nginx/public.log \
          --log-format=VCOMBINED \
          --real-time-html \
          --html-refresh=30 \
          --no-query-string \
          --anonymize-ip \
          --ignore-panel=HOSTS \
          --ws-url=wss://${domain}:443/ws \
          --port=7890 \
          -o index.html
      '';
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "10s";

      # hardening
      WorkingDirectory = "/var/www/goaccess";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = "read-only";
      ProtectSystem = "strict";
      SystemCallFilter = "~@clock @cpu-emulation @debug @keyring @memlock @module @mount @obsolete @privileged @reboot @resources @setuid @swap @raw-io";
      ReadOnlyPaths = "/";
      ReadWritePaths = [ "/proc/self" "/var/www/goaccess" ];
      PrivateDevices = "yes";
      ProtectKernelModules = "yes";
      ProtectKernelTunables = "yes";
    };
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };


  services.nginx.virtualHosts."${domain}" = {
    addSSL = true;
    enableACME = true;
    root = "/var/www/goaccess";

    locations."/ws" = {
      proxyPass = "http://127.0.0.1:7890";
      extraConfig = ''
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_buffering off;
        proxy_read_timeout 7d;
      '';
    };
  };
}
