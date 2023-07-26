{ config, self, pkgs, ... }: {

  sops.secrets.merge-bot-gitea-token = { };

  systemd.timers.job-flake-update = {
    description = "Time for flake update workflow";
    partOf = [ "job-flake-update.service" ];
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Persistent = true;
      OnCalendar = "daily";
    };
    after = [ "network-online.target" ];
  };

  # service to for automatic merge bot
  systemd.services.job-flake-update = {
    description = "Automatically update flake inputs for clan-repos";
    after = [ "network-online.target" ];
    environment = {
      GITEA_TOKEN_FILE = "%d/GITEA_TOKEN_FILE";
      # these ariables are repescted by git itself
      GIT_AUTHOR_NAME = "Clan Merge Bot";
      GIT_COMMITTER_NAME = "Clan Merge Bot";
      GIT_AUTHOR_EMAIL = "clan-bot@git.clan.lol";
      GIT_COMMITTER_EMAIL = "clan-bot@git.clan.lol";
    };
    serviceConfig = {
      LoadCredential = [ "GITEA_TOKEN_FILE:${config.sops.secrets.merge-bot-gitea-token.path}" ];
      DynamicUser = true;
      RuntimeDirectory = "job-flake-update";
    };
    path = [
      self.packages.${pkgs.system}.job-flake-update
      self.packages.${pkgs.system}.job-flake-update
    ];
    script = ''
      cd /run/job-flake-update
      mkdir -p home
      export HOME=$(realpath home)
      export REPO_DIR=$HOME/repo
      job-flake-update
    '';
  };
}
