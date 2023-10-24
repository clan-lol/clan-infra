{ pkgs, self, ... }: {

  imports = [
    ./postgresql.nix
    ./actions-runner.nix
  ];

  services.gitea = {
    enable = true;
    database = {
      type = "postgres";
      host = "/run/postgresql";
      port = 5432;
    };
    package = self.packages.${pkgs.hostPlatform.system}.gitea;

    settings.actions.ENABLED = true;
    settings.mailer = {
      ENABLED = true;
      FROM = "gitea@clan.lol";
      HOST = "localhost:25";
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
  };

  services.nginx.virtualHosts."git.clan.lol" = {
    forceSSL = true;
    enableACME = true;
    locations."/".extraConfig = ''
      proxy_pass http://localhost:3002;
    '';
  };
}
