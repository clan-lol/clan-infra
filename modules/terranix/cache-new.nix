{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Cache domain
  cache_domain = "cache.clan.lol";

  # S3 bucket details
  s3_bucket = "clan-cache";
  s3_region = "nbg1";
  s3_endpoint = "${s3_region}.your-objectstorage.com";
in
{
  # Variable for state encryption
  variable.passphrase = { };

  # Terraform providers
  terraform.required_providers.fastly = {
    source = "fastly/fastly";
  };

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
        max_conn = 200;
        name = "s3-backend";
        override_host = "${s3_bucket}.${s3_endpoint}";
        port = 443;
        shield = "frankfurt-de"; # Frankfurt shield (closest to NBG)
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
      # 404 errors
      {
        name = "is-404";
        priority = 0;
        statement = "beresp.status == 404";
        type = "CACHE";
      }
    ];

    # 404 response object
    response_object = [
      {
        name = "404-page";
        cache_condition = "is-404";
        content = "404";
        content_type = "text/plain";
        response = "Not Found";
        status = 404;
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
      # Clean headers for better caching (based on actual Ceph/Hetzner S3 headers)
      {
        destination = "http.x-amz-request-id";
        type = "cache";
        action = "delete";
        name = "remove x-amz-request-id";
      }
      {
        destination = "http.x-rgw-object-type";
        type = "cache";
        action = "delete";
        name = "remove x-rgw-object-type";
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
        name = "Remove all query strings";
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
        name = "Enable segment caching for NAR files";
        priority = 60;
        type = "recv";
      }
      # Convert S3 403 to 404 (important for Nix)
      {
        name = "cache-errors";
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
