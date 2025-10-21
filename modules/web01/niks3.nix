{ config, pkgs, ... }:
{

  services.niks3 = {
    enable = true;
    httpAddr = "127.0.0.1:5752";

    cacheUrl = "https://cache.clan.lol";

    # Hetzner Object Storage configuration
    s3 = {
      endpoint = "nbg1.your-objectstorage.com";
      bucket = "clan-cache";
      useSSL = true;
      accessKeyFile = config.clan.core.vars.generators.niks3-s3.files."access-key".path;
      secretKeyFile = config.clan.core.vars.generators.niks3-s3.files."secret-key".path;
    };

    # API authentication token (minimum 36 characters)
    apiTokenFile = config.clan.core.vars.generators.niks3-api-token.files."token".path;

    # Use niks3-specific signing key
    signKeyFiles = [ config.clan.core.vars.generators.niks3-signing-key.files."key".path ];
  };

  # NGINX reverse proxy configuration for niks3.clan.lol
  services.nginx.virtualHosts."niks3.clan.lol" = {
    forceSSL = true;
    enableACME = true;
    locations."/".extraConfig = ''
      proxy_pass http://127.0.0.1:5752;
      proxy_set_header Host $host;
      proxy_redirect http:// https://;
      proxy_http_version 1.1;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $connection_upgrade;
    '';
  };

  # Clan vars generators for niks3 secrets
  clan.core.vars.generators.niks3-s3 = {
    files."access-key" = {
      owner = config.services.niks3.user;
    };
    files."secret-key" = {
      owner = config.services.niks3.user;
    };
    prompts.access-key.type = "line";
    prompts.access-key.persist = true;
    prompts.access-key.description = "S3 Access Key for niks3";
    prompts.secret-key.type = "hidden";
    prompts.secret-key.persist = true;
    prompts.secret-key.description = "S3 Secret Key for niks3";
    script = ''
      cat "$prompts"/access-key > $out/access-key
      cat "$prompts"/secret-key > $out/secret-key
    '';
  };

  clan.core.vars.generators.niks3-api-token = {
    files."token" = {
      owner = config.services.niks3.user;
    };
    runtimeInputs = [ pkgs.openssl ];
    script = ''
      # Generate a secure random token (minimum 36 characters)
      openssl rand -hex 24 > $out/token
    '';
  };

  clan.core.vars.generators.niks3-signing-key = {
    files."key" = {
      owner = config.services.niks3.user;
    };
    files."key.pub".secret = false;
    runtimeInputs = [ pkgs.nix ];
    script = ''
      nix --extra-experimental-features "nix-command flakes" \
        key generate-secret --key-name niks3.clan.lol-1 > $out/key
      nix --extra-experimental-features "nix-command flakes" \
        key convert-secret-to-public < $out/key > $out/key.pub
    '';
  };
}
