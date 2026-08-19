{
  pkgs,
  lib,
  self,
  config,
  ...
}:

{
  imports = [
    ./postgresql.nix
    ./actions-runner.nix
    ./installer.nix
  ];

  services.gitea = {
    enable = true;
    database = {
      type = "postgres";
      host = "/run/postgresql";
      port = 5432;
    };
    lfs.enable = true;
    package = self.packages.${pkgs.stdenv.hostPlatform.system}.gitea;

    settings.actions.ENABLED = true;

    mailerPasswordFile = config.clan.core.vars.generators.gitea-mail.files.gitea-password.path;

    settings.mailer = {
      ENABLED = true;
      PROTOCOL = "smtps";
      FROM = "gitea@clan.lol";
      USER = "gitea@clan.lol";
      SMTP_ADDR = "mail.clan.lol";
      SMTP_PORT = "465";
    };

    settings.log.LEVEL = "Error";

    settings.ui = {
      ONLY_SHOW_RELEVANT_REPOS = true;
      # Must be a comma-separated string: generators.toINI cannot render a list.
      # Order here is the reaction picker order, upstream defaults first.
      REACTIONS = lib.concatStringsSep ", " [
        "+1"
        "-1"
        "laugh"
        "hooray"
        "confused"
        "heart"
        "rocket"
        "eyes"
        "thinking"
        "fire"
        "clap"
        "sob"
        "sunglasses"
        "skull"
        "muscle"
        "pray"
        "exploding_head"
        "shrug"
        "robot"
        "poop"
        "face_with_peeking_eye"
        "lying_face"
        "vomiting_face"
        "flushed"
        "troll"
        "zombie"
        "clown_face"
        "moyai"
        "cowboy_hat_face"
        "nerd_face"
        "melting_face"
        "face_with_spiral_eyes"
        "crystal_ball"
        "bomb"
        "salt"
        "sloth"
      ];
    };

    settings.service = {
      DISABLE_REGISTRATION = false;
      ENABLE_NOTIFY_MAIL = true;
    };

    # Prioritize authenticated users to reduce disruption from scrapers
    settings.qos = {
      ENABLED = true;
      # Default is 4 * CPU cores but that's too high
      MAX_INFLIGHT = 32;
    };

    settings.metrics.ENABLED = true;
    settings.server = {
      APP_DATA_PATH = "/var/lib/gitea/data";
      DISABLE_ROUTER_LOG = true;
      ROOT_URL = "https://git.clan.lol";
      # Only listen on localhost
      HTTP_ADDR = "127.0.0.1";
      HTTP_PORT = 3002;
      DOMAIN = "git.clan.lol";
      LANDING_PAGE = "explore";
    };
    settings.session.PROVIDER = "db";
    settings.session.COOKIE_SECURE = true;

    # Expose WebFinger for Tailscale OIDC
    settings.federation.ENABLED = true;
  };

  sops.secrets."vars/gitea-mail/gitea-password".owner =
    lib.mkForce config.systemd.services.gitea.serviceConfig.User;

  services.anubis.instances.gitea = {
    settings = {
      # https://anubis.techaro.lol/docs/admin/configuration/subrequest-auth
      TARGET = " ";
      BIND = "127.0.0.1:3001";
      BIND_NETWORK = "tcp";
      OG_PASSTHROUGH = true;
      # Just in case we ever stop using subrequest auth
      # https://anubis.techaro.lol/docs/admin/configuration/redirect-domains
      REDIRECT_DOMAINS = config.services.gitea.settings.server.DOMAIN;
    };

    policy = {
      # https://anubis.techaro.lol/docs/admin/configuration/subrequest-auth
      settings.status_codes = {
        CHALLENGE = 200;
        DENY = 403;
      };

      # https://github.com/TecharoHQ/anubis/blob/main/data/apps/gitea-rss-feeds.yaml
      extraBots = [
        { import = "(data)/apps/gitea-rss-feeds.yaml"; }
      ];
    };
  };

  services.nginx.clientMaxBodySize = "100M";

  # https://github.com/TecharoHQ/anubis/issues/1556
  services.nginx.additionalModules = [ pkgs.nginxModules.njs ];
  services.nginx.commonHttpConfig = ''
    js_import anubis from ${pkgs.writeText "anubis-redirect.js" ''
      function redirectToAnubis(r) {
        var uri = r.variables.scheme + "://" + r.variables.host + r.variables.request_uri;
        return "/.within.website/?redir=" + encodeURIComponent(uri);
      }

      export default { redirectToAnubis };
    ''};
    js_set $anubisRedirect anubis.redirectToAnubis;
  '';

  services.nginx.virtualHosts."git.clan.lol" = {
    forceSSL = true;
    enableACME = true;

    # https://anubis.techaro.lol/docs/admin/configuration/subrequest-auth
    locations."/" = {
      proxyPass = "http://127.0.0.1:3002";
      extraConfig = ''
        auth_request /.within.website/x/cmd/anubis/api/check;
        error_page 401 = @redirectToAnubis;
      '';
    };

    locations."/.within.website/" = {
      proxyPass = "http://127.0.0.1:3001";
      extraConfig = ''
        auth_request off;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
      '';
    };

    locations."@redirectToAnubis".extraConfig = ''
      return 307 $anubisRedirect;
      auth_request off;
    '';

    locations."= /robots.txt".alias = ./robots.txt;
  };
}
