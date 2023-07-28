{ config, self, pkgs, lib, ... }:
let

  allFlakePackages = [
    "job-flake-update-clan-core"
    "job-flake-update-clan-homepage"
    "job-flake-update-clan-infra"
  ];

  allFlakeJobs = lib.filter (lib.hasPrefix "job-") allFlakePackages;

  allSystemdConfigs = map configForJob allFlakeJobs;

  configForJob = name: {
    systemd.timers.${name} = {
      description = "Time for flake update workflow";
      partOf = [ "${name}.service" ];
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Persistent = true;
        OnCalendar = "daily";
      };
      after = [ "network-online.target" ];
    };

    # service to for automatic merge bot
    systemd.services.${name} = {
      description = "Automatically update flake inputs for clan-repos";
      after = [ "network-online.target" ];
      environment = {
        # secrets
        GITEA_TOKEN_FILE = "%d/GITEA_TOKEN_FILE";
        CLAN_BOT_SSH_KEY_FILE = "%d/CLAN_BOT_SSH_KEY_FILE";

        HOME = "/run/${name}";

        # used by action-checkout
        REPO_DIR = "/run/${name}/repo";

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
        RuntimeDirectory = "${name}";
        WorkingDirectory = "/run/${name}";
        ExecStart = "${self.packages.${pkgs.system}.${name}}/bin/${name}";
      };
    };
  };

in
{
  config = lib.mkMerge (
    allSystemdConfigs
    ++ [
      {
        sops.secrets.clan-bot-gitea-token = { };
        sops.secrets.clan-bot-ssh-key = { };
      }
    ]
  );
}
