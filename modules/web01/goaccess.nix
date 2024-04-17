{ stdenv, lib, pkgs, ... }:

let
  domain = "metrics.clan.lol";
  priv_goaccess = "/var/lib/goaccess";
  pub_goaccess = "/var/www/goaccess";

  user-agent-list = pkgs.writeText "browsers.list" ''
        # List of browsers and their categories
        # e.g., WORD delimited by tab(s) \t TYPE
        # TYPE can be any type and it's not limited to the ones below.
        matrix	Matrix-Preview
    		slack	Slack
        github-actions-checkout	GitHubActions
        git	Git
        connect-go	Go
        Go-http-client	Go
        curl	Curl
  '';
in
{
  users.users.goaccess = {
    isSystemUser = true;
    group = "nginx";
    createHome = true;
    home = "${pub_goaccess}";
    homeMode = "0774";
  };

  services.nginx.commonHttpConfig = ''
    log_format vcombined '$host:$server_port $remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referrer" "$http_user_agent"';
    access_log /var/log/nginx/private.log vcombined;
  '';

  systemd.tmpfiles.rules = [
    "d ${priv_goaccess} 0755 goaccess nginx -"
    "d ${priv_goaccess}/db 0755 goaccess nginx -"
    "d ${pub_goaccess} 0755 goaccess nginx -"
  ];


  # --browsers-file=/etc/goaccess/browsers.list
  # https://raw.githubusercontent.com/allinurl/goaccess/master/config/browsers.list
  systemd.services.goaccess = {
    description = "GoAccess server monitoring";
    preStart = ''
      			rm -f ${pub_goaccess}/index.html
      		'';
    serviceConfig = {
      User = "goaccess";
      Group = "nginx";
      ExecStart = ''
        ${pkgs.goaccess}/bin/goaccess \
          -f /var/log/nginx/public.log \
          --log-format=VCOMBINED \
          --ignore-crawlers \
          --browsers-file=${user-agent-list} \
          --real-time-html \
          --all-static-files \
          --html-refresh=30 \
          --persist \
          --restore \
          --db-path=${priv_goaccess}/db \
          --no-query-string \
          --unknowns-log=${priv_goaccess}/unknowns.log \
          --invalid-requests=${priv_goaccess}/invalid-requests.log \
          --anonymize-ip \
          --ignore-panel=HOSTS \
          --ws-url=wss://${domain}:443/ws \
          --port=7890 \
          -o "${pub_goaccess}/index.html"
      '';
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "10s";

      # hardening
      WorkingDirectory = "${pub_goaccess}";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = "read-only";
      ProtectSystem = "strict";
      SystemCallFilter = "~@clock @cpu-emulation @debug @keyring @memlock @module @mount @obsolete @privileged @reboot @resources @setuid @swap @raw-io";
      ReadOnlyPaths = "/";
      ReadWritePaths = [ "/proc/self" "${pub_goaccess}" "${priv_goaccess}" ];
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
    root = "${pub_goaccess}";

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
