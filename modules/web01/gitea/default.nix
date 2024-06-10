{
  pkgs,
  lib,
  self,
  config,
  ...
}:

let
  # make the logs for this host "public" so that they show up in e.g. metrics
  publog =
    vhost:
    lib.attrsets.unionOfDisjoint vhost {
      extraConfig =
        (vhost.extraConfig or "")
        + ''
          access_log /var/log/nginx/public.log vcombined;
        '';
    };
in
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
    package = self.packages.${pkgs.hostPlatform.system}.gitea;

    settings.actions.ENABLED = true;

    mailerPasswordFile = config.clanCore.facts.services.gitea-mail.secret.gitea-password.path;

    settings.mailer = {
      ENABLED = true;
      FROM = "gitea@clan.lol";
      USER = "gitea@clan.lol";
      SMTP_ADDR = "mail.clan.lol";
      SMTP_PORT = "587";
    };

    settings.log.LEVEL = "Error";
    settings.service.DISABLE_REGISTRATION = false;
    settings.metrics.ENABLED = true;
    settings.server = {
      APP_DATA_PATH = "/var/lib/gitea/data";
      DISABLE_ROUTER_LOG = true;
      ROOT_URL = "https://git.clan.lol";
      HTTP_PORT = 3002;
      DOMAIN = "git.clan.lol";
      LANDING_PAGE = "explore";
    };
    settings.session.PROVIDER = "db";
    settings.session.COOKIE_SECURE = true;
  };

  sops.secrets.web01-gitea-password.owner = config.systemd.services.gitea.serviceConfig.User;

  services.nginx.virtualHosts."git.clan.lol" = publog {
    forceSSL = true;
    enableACME = true;
    locations."/".extraConfig = ''
      proxy_pass http://localhost:3002;
    '';
  };
}
