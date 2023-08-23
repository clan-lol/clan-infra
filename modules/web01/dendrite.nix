{ config
, pkgs
, ...
}:
let
  database = {
    connection_string = "postgres:///dendrite?host=/run/postgresql";
    max_open_conns = 100;
    max_idle_conns = 5;
    conn_max_lifetime = -1;
  };
  inherit (config.services.dendrite.settings.global) server_name;
  domain = "clan.lol";
  nginx-vhost = "matrix.${domain}";
  element-web =
    pkgs.runCommand "element-web-with-config"
      {
        nativeBuildInputs = [ pkgs.buildPackages.jq ];
      } ''
      cp -r ${pkgs.element-web} $out
      chmod -R u+w $out
      jq '."default_server_config"."m.homeserver" = { "base_url": "https://${nginx-vhost}:443", "server_name": "${server_name}" }' \
        > $out/config.json < ${pkgs.element-web}/config.json
      ln -s $out/config.json $out/config.${nginx-vhost}.json
    '';
in
{
  services.dendrite = {
    enable = true;
    httpPort = 8043;
    # $ echo "REGISTRATION_SHARED_SECRET=$(openssl rand -base64 32)"

    # To create a user:
    # $ password=$(nix run "nixpkgs#xkcdpass" -- -n 3 -d-)
    # $ shared_secret=$(sops -d --extract '["registration-secret"]' ./secrets.yaml| sed s/REGISTRATION_SHARED_SECRET=//)
    # $ nix shell "nixpkgs#matrix-synapse" -c register_new_matrix_user --password "${password}" --shared-secret "${shared_secret}" "https://matrix.clan.lol:443"
    environmentFile = config.sops.secrets.registration-secret.path;

    settings = {
      sync_api.search = {
        enabled = true;
        index_path = "/var/lib/dendrite/searchindex";
      };
      global = {
        server_name = domain;
        # `private_key` has the type `path`
        # prefix a `/` to make `path` happy
        private_key = "/$CREDENTIALS_DIRECTORY/matrix-server-key";
        trusted_third_party_id_servers = [
          "matrix.org"
          "vector.im"
        ];
        metrics.enabled = true;
      };
      logging = [
        {
          type = "std";
          level = "warn";
        }
      ];
      app_service_api = {
        inherit database;
        config_files = [ ];
      };
      client_api = {
        registration_disabled = true;
        rate_limiting.enabled = false;
        registration_shared_secret = ''''${REGISTRATION_SHARED_SECRET}'';
      };
      media_api = {
        inherit database;
        dynamic_thumbnails = true;
      };
      room_server = {
        inherit database;
      };
      push_server = {
        inherit database;
      };
      relay_api = {
        inherit database;
      };
      mscs = {
        inherit database;
        mscs = [ "msc2836" "msc2946" ];
      };
      sync_api = {
        inherit database;
        real_ip_header = "X-Real-IP";
      };
      key_server = {
        inherit database;
      };
      federation_api = {
        inherit database;
        key_perspectives = [
          {
            server_name = "matrix.org";
            keys = [
              {
                key_id = "ed25519:auto";
                public_key = "Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw";
              }
              {
                key_id = "ed25519:a_RXGa";
                public_key = "l8Hft5qXKn1vfHrg3p4+W8gELQVo8N13JkluMfmn2sQ";
              }
            ];
          }
        ];
        prefer_direct_fetch = false;
      };
      user_api = {
        account_database = database;
        device_database = database;
      };
    };
  };

  systemd.services.dendrite.serviceConfig.LoadCredential = [
    # $ nix-shell -p dendrite --run 'generate-keys --private-key /tmp/key'
    "matrix-server-key:${config.sops.secrets.matrix-server-key.path}"
  ];

  systemd.services.dendrite.after = [ "postgresql.service" ];
  services.postgresql = {
    ensureDatabases = [ "dendrite" ];
    ensureUsers = [
      {
        name = "dendrite";
        ensurePermissions."DATABASE dendrite" = "ALL PRIVILEGES";
      }
    ];
  };

  services.nginx.virtualHosts.${nginx-vhost} = {
    forceSSL = true;
    enableACME = true;
    extraConfig = ''
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_read_timeout 600;
    '';
    locations."/_matrix".proxyPass = "http://127.0.0.1:${toString config.services.dendrite.httpPort}";
    # for remote admin access
    locations."/_synapse".proxyPass = "http://127.0.0.1:${toString config.services.dendrite.httpPort}";
    locations."/".root = element-web;
  };
}
