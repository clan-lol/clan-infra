{ config, pkgs, ... }:

{
  # www user to push website artifacts via ssh
  users.users.www = {
    openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys ++ [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyHjnmRUbCw8EP350+4K0KOHPiTzTpTBrOQUzNINOrx gitea-ci"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGmAw62wkSAvzAKwZn3xFvCj+jUkOgp2arABA6PEbc8 clan-www2" # key for git.clan.lol/clan/data-mesher gitea-ci
    ];
    isSystemUser = true;
    shell = pkgs.bash;
    group = "www";
  };
  users.groups.www = { };

  # ensure /var/www can be accessed by nginx and www user
  systemd.tmpfiles.rules = [
    "d /var/www 0755 www nginx"
    "d /var/www/static.clan.lol 0755 www nginx"
    "d /var/www/vpnbench 0755 www nginx"
    "d /var/www/versioned-docs 0755 www nginx"
  ];

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
      # Versioned docs: /docs/<VERSION>/* serves from /var/www/versioned-docs/<VERSION>/docs/<VERSION>/*
      # Each release branch deploys via rsync into /var/www/versioned-docs/<VERSION>/
      # Assets are referenced as absolute paths /_assets/<VERSION>/... and /_app/...
      locations."= /docs".return = "301 /docs/25.11";
      locations."= /docs/".return = "301 /docs/25.11";
      locations."= /docs/versions".extraConfig = ''
        proxy_pass https://git.clan.lol/clan/clan-core/raw/branch/main/pkgs/clan-site/static/docs/versions;
        proxy_set_header Host git.clan.lol;
        proxy_ssl_server_name on;
        proxy_ssl_name git.clan.lol;
        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
      '';
      # Serve versioned docs from /var/www/versioned-docs/<VERSION>/
      # URL: /docs/<VERSION>/path  →  /var/www/versioned-docs/<VERSION>/docs/<VERSION>/path
      # URL: /_assets/<VERSION>/path  →  /var/www/versioned-docs/<VERSION>/_assets/<VERSION>/path
      #
      # The entire versioned site tree lives under /var/www/versioned-docs/<VERSION>/
      # so we set root to that and rewrite to the internal path.
      # We use an internal named location for .html fallback.
      locations."~ ^/(docs|_assets)/(?<version>[^/]+)(?<vpath>/.*)?$".extraConfig = ''
        root /var/www/versioned-docs/$version;
        set $section $1;

        # Redirect trailing slash to non-trailing slash for clean URLs
        # (except for bare /docs/<version>/ which is fine)
        rewrite ^(.+)/$ $1 permanent;

        # try_files paths are relative to root
        # e.g. for /docs/unstable/getting-started with root=/var/www/versioned-docs/unstable
        # tries: /docs/unstable/getting-started, /docs/unstable/getting-started.html, /docs/unstable/getting-started/index.html
        try_files /$section/$version$vpath /$section/$version''${vpath}.html /$section/$version$vpath/index.html =404;

        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
      '';

      locations."/wclan".return = "307 https://clan.lol/";
      locations."/what-is-clan".return = "307 https://clan.lol";
      locations."/thaigersprint".return = "307 https://pad.lassul.us/s/clan-thaigersprint";
      locations."/blog/hello-world/".return = "307 https://clan.lol/blog/introduction-clan/";
    };

    virtualHosts."data-mesher.docs.clan.lol" = {
      forceSSL = true;
      enableACME = true;
      # to be deployed via rsync
      root = "/var/www/data-mesher.docs.clan.lol";
      extraConfig = ''
        charset utf-8;
        source_charset utf-8;
      '';

      # Make sure to expire the cache after 12 hour
      locations."/".extraConfig = ''
        add_header Cache-Control "public, max-age=43200";
      '';
    };

    # TODO: Once clan.lol/docs is verified working, redirect docs.clan.lol to clan.lol/docs
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
        try_files $uri $uri.html $uri/ $uri/index.html =404;
      '';
      locations."/blog/2024/03/19/introducing-clan-full-stack-computing-redefined/".return =
        "307 https://clan.lol/blog/introduction-clan/";
      locations."/blog/2024/05/25/jsonschema-converter/".return =
        "307 https://clan.lol/blog/json-schema-converter/";
      locations."/blog/2024/06/24/backups/".return =
        "307 https://clan.lol/blog/declarative-backups-and-restore/";
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

    virtualHosts."static.clan.lol" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/www/static.clan.lol";
      extraConfig = ''
        charset utf-8;
        source_charset utf-8;
        autoindex off;
      '';

      # Cache static files for 1 week
      locations."/".extraConfig = ''
        add_header Cache-Control "public, max-age=604800, immutable";
        add_header Access-Control-Allow-Origin "https://clan.lol" always;
      '';
    };

    virtualHosts."blog.clan.lol" = {
      forceSSL = true;
      enableACME = true;
      globalRedirect = "clan.lol/blog";
    };

    virtualHosts."vpnbench.clan.lol" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/www/vpnbench";
      extraConfig = ''
        charset utf-8;
        source_charset utf-8;
      '';

      locations."/".extraConfig = ''
        try_files $uri $uri/ /index.html;
      '';
    };
  };
}
