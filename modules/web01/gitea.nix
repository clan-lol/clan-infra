{ pkgs, ... }: {

  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql_14;
  services.postgresql.settings = {
    max_connections = "300";
    shared_buffers = "80MB";
  };
  services.postgresqlBackup.enable = true;

  services.gitea = {
    enable = true;
    database = {
      type = "postgres";
      host = "/run/postgresql";
      port = 5432;
    };
    #mailerPasswordFile = config.sops.secrets.gitea-mail.path;
    settings.mailer = {
      ENABLED = true;
      FROM = "gitea@clan.lol";
      HOST = "localhost:25";
    };
    settings.log.LEVEL = "Error";
    # TODO: prevent spammers from logging in, before enabling registration
    settings.service.DISABLE_REGISTRATION = true;
    settings.metrics.ENABLED = true;
    settings.server = {
      DISABLE_ROUTER_LOG = true;
      ROOT_URL = "https://git.clan.lol";
      HTTP_PORT = 3002;
      DOMAIN = "git.clan.lol";
    };
  };

  services.nginx.virtualHosts."git.clan.lol" = {
    forceSSL = true;
    enableACME = true;
    locations."/".extraConfig = ''
      proxy_pass http://localhost:3002;
    '';
  };

}
