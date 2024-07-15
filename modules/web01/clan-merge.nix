{
  config,
  self,
  pkgs,
  ...
}:
{
  # service to for automatic merge bot
  systemd.services.clan-merge = {
    description = "Merge clan.lol PRs automatically";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment = {
      GITEA_TOKEN_FILE = "%d/GITEA_TOKEN_FILE";
    };
    serviceConfig = {
      LoadCredential = [ "GITEA_TOKEN_FILE:${config.sops.secrets.merge-bot-gitea-token.path}" ];
      Restart = "on-failure";
      DynamicUser = true;
    };
    script = ''
      while sleep 10; do
        ${self.packages.${pkgs.system}.clan-merge}/bin/clan-merge \
          --bot-name clan-bot \
          --repos clan-infra clan-core clan-homepage data-mesher
      done
    '';
  };
}
