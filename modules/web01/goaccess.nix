{ stdenv, lib, pkgs, ... }:
let
  # make the logs for this host "public" so that they show up in e.g. metrics
  publog = vhost: lib.attrsets.unionOfDisjoint vhost {
    extraConfig = (vhost.extraConfig or "") + ''
      access_log /var/log/nginx/public.log vcombined;
    '';
  };
in
{

  publog.publog = publog;

  services.nginx.commonHttpConfig = ''
    log_format vcombined '$host:$server_port $remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referrer" "$http_user_agent"';
    access_log /var/log/nginx/private.log vcombined;
  '';

  systemd.services.goaccess = {
    description = "GoAccess server monitoring";
    serviceConfig = {
      ExecStart = ''
        ${pkgs.goaccess}/bin/goaccess \
          -f /var/log/nginx/public.log \
          --log-format=VCOMBINED \
          --real-time-html \
          --html-refresh=30 \
          --no-query-string \
          --anonymize-ip \
          --ignore-panel=HOSTS \
          --ws-url=wss://metrics.clan.lol:443/ws \
          --port=7890 \
          -o /var/www/goaccess/index.html
      '';
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "10s";

      # hardening
      WorkingDirectory = "/tmp";
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

  # server statistics
  services.nginx.virtualHosts."metrics.clan.lol" = {
    addSSL = true;
    enableACME = true;
    # inherit kTLS;
    root = "/var/www/goaccess";

    locations."/ws" = {
      proxyPass = "http://127.0.0.1:7890";
      # XXX not sure how much of this is necessary
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
