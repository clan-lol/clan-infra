{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Cache domain
  cache_domain = "cache.clan.lol";

  # Backblaze B2 bucket details (S3-compatible)
  s3_bucket = "clan-cache";
  s3_region = "eu-central-003";
  s3_endpoint = "s3.${s3_region}.backblazeb2.com";
in
{
  # Variable for state encryption
  variable.passphrase = { };

  # Terraform providers
  terraform.required_providers.fastly.source = "fastly/fastly";
  terraform.required_providers.b2.source = "Backblaze/b2";

  # Fastly API key from secrets
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

  # B2 credentials from secrets
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

  # Application key for Fastly to read from B2 (S3-compatible)
  # References the bucket created in cache.nix
  resource.b2_application_key.fastly-prod = {
    key_name = "fastly-prod";
    capabilities = [ "readFiles" ];
    bucket_id = "3ce17c7644b1072d93b40c1c"; # clan-cache bucket ID
  };

  # Application key for niks3 to write to B2 (S3-compatible)
  resource.b2_application_key.niks3 = {
    key_name = "niks3";
    capabilities = [
      "deleteFiles"
      "listBuckets"
      "listFiles"
      "readBucketEncryption"
      "readBucketLogging"
      "readBucketNotifications"
      "readBucketReplications"
      "readBuckets"
      "readFiles"
      "shareFiles"
      "writeBucketEncryption"
      "writeBucketLogging"
      "writeBucketNotifications"
      "writeBucketReplications"
      "writeBuckets"
      "writeFiles"
    ];
    bucket_id = "3ce17c7644b1072d93b40c1c"; # clan-cache bucket ID

    # Write credentials to clan vars for web01
    provisioner.local-exec = [
      {
        command = ''
          echo '${lib.tf.ref "self.application_key_id"}' | clan vars set web01 niks3-s3/access-key
        '';
      }
      {
        command = ''
          echo '${lib.tf.ref "self.application_key"}' | clan vars set web01 niks3-s3/secret-key
        '';
      }
    ];
  };

  # Fastly service for cache.clan.lol
  resource.fastly_service_vcl.cache_new = {
    name = cache_domain;
    default_ttl = 86400; # 24 hours

    # NOTE: Domain must be added manually via Fastly dashboard
    # The terraform provider's domain API is deprecated (returns 400)
    # Add cache.clan.lol at: https://manage.fastly.com/configure/services/l864Jj5vHcp8xzy9fONPwq/domains

    # S3 backend
    backend = [
      {
        address = s3_endpoint;
        auto_loadbalance = false;
        between_bytes_timeout = 10000;
        connect_timeout = 5000;
        error_threshold = 0;
        first_byte_timeout = 15000;
        healthcheck = "s3-health";
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

    # Health check to detect slow S3 responses
    # If S3 can't respond to nix-cache-info within 3s, mark as unhealthy
    healthcheck = [
      {
        name = "s3-health";
        host = "${s3_bucket}.${s3_endpoint}";
        path = "/nix-cache-info";
        check_interval = 5000; # Check every 5 seconds
        timeout = 3000; # 3 second timeout
        threshold = 2; # 2 successful checks to mark healthy
        window = 3; # Out of last 3 checks
        initial = 2; # Start as healthy
        method = "GET";
        expected_response = 200;
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
      # If S3 backend is unhealthy (slow), immediately return 404
      # This prevents clients from waiting for timeouts when S3 is slow
      # Exception: nix-cache-info uses stale content via grace period
      {
        content = ''
          if (!req.backend.healthy && req.url.path !~ "^/nix-cache-info") {
            error 404 "Backend unhealthy";
          }
        '';
        name = "vcl_recv - Return 404 if backend unhealthy";
        priority = 55;
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
              (config.resource.b2_application_key.fastly-prod "application_key_id")
              (config.resource.b2_application_key.fastly-prod "application_key")
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
    ];
  };

  # TLS certificate
  resource.fastly_tls_subscription.cache_new = {
    domains = [ cache_domain ];
    certificate_authority = "certainly";
  };

  # Outputs
  output.cache_new_domain = {
    value = cache_domain;
  };

  output.cache_new_service_id = {
    value = "\${fastly_service_vcl.cache_new.id}";
  };

  output.cache_new_tls_subscription_id = {
    value = "\${fastly_tls_subscription.cache_new.id}";
  };

  output.cache_new_managed_dns_challenges = {
    value = "\${fastly_tls_subscription.cache_new.managed_dns_challenges}";
    description = "ACME challenge records for cache.clan.lol - add these to DNS";
  };
}
