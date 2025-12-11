{ config, pkgs, ... }:
{
  services.niks3 = {
    enable = true;
    httpAddr = "127.0.0.1:5752";

    cacheUrl = "https://cache.clan.lol";

    # Backblaze B2 configuration (S3-compatible)
    s3 = {
      endpoint = "s3.eu-central-003.backblazeb2.com";
      bucket = "clan-cache";
      useSSL = true;
      accessKeyFile = config.clan.core.vars.generators.niks3-s3.files."access-key".path;
      secretKeyFile = config.clan.core.vars.generators.niks3-s3.files."secret-key".path;
    };

    # API authentication token (minimum 36 characters)
    apiTokenFile = config.clan.core.vars.generators.niks3-api-token.files."token".path;

    # Use niks3-specific signing key
    signKeyFiles = [ config.clan.core.vars.generators.niks3-signing-key.files."key".path ];

    # Use the built-in nginx option
    nginx.enable = true;
    nginx.domain = "niks3.clan.lol";
  };

  # Clan vars for niks3 S3 credentials (populated by terraform via cache-new)
  clan.core.vars.generators.niks3-s3 = {
    files."access-key" = {
      owner = "niks3";
      deploy = config.services.niks3.enable;
    };
    files."secret-key" = {
      owner = "niks3";
      deploy = config.services.niks3.enable;
    };
    script = ''
      echo "niks3-s3 credentials are populated by terraform (cache-new), not generated" >&2
      exit 1
    '';
  };

  clan.core.vars.generators.niks3-api-token = {
    files."token" = {
      owner = "niks3";
      deploy = config.services.niks3.enable;
    };
    runtimeInputs = [ pkgs.openssl ];
    script = ''
      # Generate a secure random token (minimum 36 characters)
      openssl rand -hex 24 > $out/token
    '';
  };

  clan.core.vars.generators.niks3-signing-key = {
    files."key" = {
      owner = "niks3";
      deploy = config.services.niks3.enable;
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
