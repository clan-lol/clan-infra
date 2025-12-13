{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Cache domain
  cache_domain = "cache2.clan.lol";

  # Backblaze B2 bucket details (S3-compatible)
  s3_bucket = "clan-cache";
  s3_region = "eu-central-003";
  s3_endpoint = "s3.${s3_region}.backblazeb2.com";
in
{
  variable.passphrase = { };

  terraform.required_providers.fastly.source = "fastly/fastly";
  terraform.required_providers.b2.source = "Backblaze/b2";

  data.external.fastly-api-key = {
    program = [
      (lib.getExe (
        pkgs.writeShellApplication {
          name = "get-fastly-secret";
          text = ''
            jq -n --arg secret "$(clan secrets get fastly-api-key)" '{"secret":$secret}'
          '';
        }
      ))
    ];
  };

  provider.fastly.api_key = config.data.external.fastly-api-key "result.secret";

  data.external.b2-key-id = {
    program = [
      (lib.getExe (
        pkgs.writeShellApplication {
          name = "get-clan-secret";
          text = ''
            jq -n --arg secret "$(clan secrets get b2-key-id)" '{"secret":$secret}'
          '';
        }
      ))
    ];
  };

  data.external.b2-application-key = {
    program = [
      (lib.getExe (
        pkgs.writeShellApplication {
          name = "get-clan-secret";
          text = ''
            jq -n --arg secret "$(clan secrets get b2-application-key)" '{"secret":$secret}'
          '';
        }
      ))
    ];
  };

  provider.b2.application_key_id = config.data.external.b2-key-id "result.secret";
  provider.b2.application_key = config.data.external.b2-application-key "result.secret";

  resource.b2_bucket.cache = {
    bucket_name = "clan-cache";
    bucket_type = "allPrivate";
  };

  # Application key for Fastly to read from B2 (S3-compatible)
  resource.b2_application_key.fastly = {
    key_name = "fastly";
    capabilities = [ "readFiles" ];
    bucket_ids = [ (config.resource.b2_bucket.cache "id") ];
  };

  # Fastly service for cache2.clan.lol
  resource.fastly_service_vcl.cache = {
    name = cache_domain;
    default_ttl = 86400; # 24 hours

    # NOTE: Domain must be added manually via Fastly dashboard
    # The terraform provider's domain API is deprecated (returns 400)
    # cache2.clan.lol should already be configured at: https://manage.fastly.com/configure/services/R3YzKvkDNI44XEyD4pEjzB/domains

    # S3 backend
    backend = [
      {
        address = s3_endpoint;
        auto_loadbalance = false;
        between_bytes_timeout = 10000;
        connect_timeout = 5000;
        error_threshold = 0;
        first_byte_timeout = 15000;
        max_conn = 200;
        name = "s3-backend";
        override_host = "${s3_bucket}.${s3_endpoint}";
        port = 443;
        shield = "frankfurt-de"; # Frankfurt shield (closest to B2 eu-central-003)
        ssl_cert_hostname = "${s3_bucket}.${s3_endpoint}";
        ssl_check_cert = true;
        use_ssl = true;
        weight = 100;
      }
    ];

    # Force HTTPS
    request_setting = [
      {
        name = "Redirect HTTP to HTTPS";
        force_ssl = true;
      }
    ];

    # Conditions
    condition = [
      # Match root path for landing page redirect
      {
        name = "match-root";
        priority = 10;
        statement = ''req.url ~ "^/$"'';
        type = "REQUEST";
      }
    ];

    # Headers
    header = [
      # Rewrite root path to index.html (landing page)
      {
        action = "set";
        destination = "url";
        ignore_if_set = false;
        name = "Landing page";
        priority = 10;
        request_condition = "match-root";
        source = ''"/index.html"'';
        type = "request";
      }
      # Clean headers for better caching
      {
        destination = "http.x-amz-request-id";
        type = "cache";
        action = "delete";
        name = "remove x-amz-request-id";
      }
      # Enable Streaming Miss
      {
        priority = 20;
        destination = "do_stream";
        type = "cache";
        action = "set";
        name = "Enabling Streaming Miss";
        source = "true";
      }
      # CORS headers
      {
        destination = "http.access-control-allow-origin";
        type = "response";
        action = "set";
        name = "CORS Allow";
        source = ''"*"'';
      }
      # Add debug header for bucket name
      {
        destination = "http.x-debug-bucket";
        type = "response";
        action = "set";
        name = "Debug bucket name";
        source = ''"${s3_bucket}"'';
      }
    ];

    # VCL Snippets
    snippet = [
      # Remove query strings (better cache hits)
      {
        content = "set req.url = querystring.remove(req.url);";
        name = "vcl_recv - Remove query strings";
        priority = 50;
        type = "recv";
      }
      # Enable segmented caching for large NAR files (>2GB support)
      {
        content = ''
          if (req.url.path ~ "^/nar/") {
            set req.enable_segmented_caching = true;
          }
        '';
        name = "vcl_recv - Enable segmented caching for NAR files";
        priority = 60;
        type = "recv";
      }
      # Authenticate S3 requests to B2 using AWS Signature V4
      {
        name = "vcl_miss - Authenticate S3 requests";
        priority = 100;
        type = "miss";
        content =
          builtins.replaceStrings
            [ "\${backend_domain}" "\${s3_region}" "\${access_key}" "\${secret_key}" ]
            [
              "${s3_bucket}.${s3_endpoint}"
              s3_region
              (config.resource.b2_application_key.fastly "application_key_id")
              (config.resource.b2_application_key.fastly "application_key")
            ]
            (builtins.readFile ./cache/s3-authn.vcl);
      }
      # Set long cache time for nix-cache-info with extended grace period
      # This ensures the cache remains available even during backend issues
      {
        content = ''
          if (req.url.path == "/nix-cache-info") {
            set beresp.ttl = 1h;
            set beresp.grace = 168h;  # 7 days grace period
          }
        '';
        name = "vcl_fetch - Set long TTL and grace for nix-cache-info";
        priority = 110;
        type = "fetch";
      }
      # Convert S3 403 to 404 (important for Nix)
      {
        name = "vcl_fetch - Convert S3 403 to 404";
        content = ''
          if (beresp.status == 403) {
            set beresp.status = 404;
          }
        '';
        priority = 100;
        type = "fetch";
      }
      # Add Content-Encoding header for zstd-compressed metadata files
      # Exclude .nar.zst files as Nix handles their decompression itself
      # Only set for successful responses (not 404s)
      {
        name = "vcl_fetch - Add Content-Encoding for zstd metadata";
        content = ''
          if (beresp.status == 200 && (req.url.path ~ "\.(narinfo|ls)$" || req.url.path ~ "^/realisations/" || req.url.path ~ "^/log/")) {
            set beresp.http.Content-Encoding = "zstd";
          }
        '';
        priority = 105;
        type = "fetch";
      }
    ];
  };

  # TLS certificate
  resource.fastly_tls_subscription.cache = {
    domains = [ cache_domain ];
    certificate_authority = "certainly";
  };

  # Outputs
  output.cache_domain = {
    value = cache_domain;
  };

  output.service_id = {
    value = "\${fastly_service_vcl.cache.id}";
  };
}
