{ config, ... }:

{
  clan.nginx.acme.email = "admins@clan.lol";

  # www user to push website artifacts via ssh
  users.users.www = {
    openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys ++ [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyHjnmRUbCw8EP350+4K0KOHPiTzTpTBrOQUzNINOrx gitea-ci"
    ];
    isSystemUser = true;
    shell = "/run/current-system/sw/bin/bash";
    group = "www";
  };
  users.groups.www = { };

  # ensure /var/www can be accessed by nginx and www user
  systemd.tmpfiles.rules = [ "d /var/www 0755 www nginx" ];

  services.nginx = {

    virtualHosts."clan.lol" = {
      forceSSL = true;
      enableACME = true;
      # to be deployed via rsync
      root = "/var/www/clan.lol";
      extraConfig = ''
        charset utf-8;
        source_charset utf-8;
      '';

      locations."/".extraConfig = ''
        set $cors "false";

        # Allow cross-origin requests from docs.clan.lol
        if ($http_origin = "https://docs.clan.lol") {
            set $cors "true";
        }

        # Allow cross-origin requests from localhost IPs with port 8000
        if ($http_origin = "http://localhost:8000") {
            set $cors "true";
        }

        if ($http_origin = "http://127.0.0.1:8000") {
            set $cors "true";
        }

        if ($http_origin = "http://[::1]:8000") {
            set $cors "true";
        }

        if ($cors = "true") {
            add_header 'Access-Control-Allow-Origin' "$http_origin" always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'Origin, X-Requested-With, Content-Type, Accept, Authorization' always;
        }

        if ($cors = "true") {
            add_header 'Access-Control-Allow-Origin' "$http_origin" always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'Origin, X-Requested-With, Content-Type, Accept, Authorization' always;
        }
      '';
      locations."^~ /docs".extraConfig = ''
        rewrite ^/docs(.*)$ https://docs.clan.lol permanent;
      '';
      locations."/wclan".return = "307 https://clan.lol/";
      locations."/what-is-clan".return = "307 https://clan.lol";
      locations."/thaigersprint".return = "307 https://pad.lassul.us/s/clan-thaigersprint";
      locations."/blog/hello-world/".return = "307 https://clan.lol/blog/introduction-clan/";
    };

    virtualHosts."docs.clan.lol" = {
      forceSSL = true;
      enableACME = true;
      # to be deployed via rsync
      root = "/var/www/docs.clan.lol";
      extraConfig = ''
        charset utf-8;
        source_charset utf-8;
      '';

      # Make sure to expire the cache after 12 hour
      locations."/".extraConfig = ''
        add_header Cache-Control "public, max-age=43200";
      '';
      locations."/blog/2024/03/19/introducing-clan-full-stack-computing-redefined/".return = "307 https://clan.lol/blog/introduction-clan/";
      locations."/blog/2024/05/25/jsonschema-converter/".return = "307 https://clan.lol/blog/json-schema-converter/";
      locations."/blog/2024/06/24/backups/".return = "307 https://clan.lol/blog/declarative-backups-and-restore/";
      locations."/blog/2024/07/19/nixos-facter/".return = "307 https://clan.lol/blog/nixos-facter/";
      locations."/blog/2024/09/11/interfaces/".return = "307 https://clan.lol/blog/interfaces/";

      locations."^~ /blog".extraConfig = ''
        rewrite ^/wclan(.*)$ https://clan.lol/blog permanent;
      '';
    };

    virtualHosts."www.clan.lol" = {
      forceSSL = true;
      enableACME = true;
      globalRedirect = "clan.lol";
    };
  };
}
