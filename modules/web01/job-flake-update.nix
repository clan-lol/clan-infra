{ config, self, pkgs, ... }: {

  sops.secrets.clan-bot-gitea-token = { };
  sops.secrets.clan-bot-ssh-key = { };

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
      # secrets
      GITEA_TOKEN_FILE = "%d/GITEA_TOKEN_FILE";
      CLAN_BOT_SSH_KEY_FILE = "%d/CLAN_BOT_SSH_KEY_FILE";

      HOME = "/run/job-flake-update";

      # used by action-checkout
      REPO_DIR = "/run/job-flake-update/repo";

      # used by git
      GIT_SSH_COMMAND = "ssh -i %d/CLAN_BOT_SSH_KEY_FILE -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";

      # prevent these variables from being unset by writePureShellScript
      KEEP_VARS = "GIT_SSH_COMMAND GITEA_TOKEN_FILE";
    };
    serviceConfig = {
      LoadCredential = [
        "GITEA_TOKEN_FILE:${config.sops.secrets.clan-bot-gitea-token.path}"
        "CLAN_BOT_SSH_KEY_FILE:${config.sops.secrets.clan-bot-ssh-key.path}"
      ];
      DynamicUser = true;
      RuntimeDirectory = "job-flake-update";
      WorkingDirectory = "/run/job-flake-update";
      ExecStart = "${self.packages.${pkgs.system}.job-flake-update}/bin/job-flake-update";
    };
  };
}
