{ config, lib, ... }:
{
  services.buildbot-nix.master = {
    enable = true;
    # Domain name under which the buildbot frontend is reachable
    domain = "buildbot.clan.lol";
    # The workers file configures credentials for the buildbot workers to connect to the master.
    # "name" is the configured worker name in services.buildbot-nix.worker.name of a worker
    # (defaults to the hostname of the machine)
    # "pass" is the password for the worker configured in `services.buildbot-nix.worker.workerPasswordFile`
    # "cores" is the number of cpu cores the worker has.
    # The number must match as otherwise potentially not enought buildbot-workers are created.
    workersFile = config.sops.secrets.buildbot-workers-file.path;
    buildSystems = [ "x86_64-linux" ];

    authBackend = "gitea";

    admins =
      lib.mapAttrsToList (_: user: user.gitea.username) (
        lib.filterAttrs (_: user: user.isNormalUser) config.users.users
      )
      ++ [
        "brianmcgee"
      ];

    gitea = {
      enable = true;
      instanceUrl = "https://git.clan.lol";
      # Redirect URIs. Please use a new line for every URI: https://buildbot.clan.lol/auth/login
      oauthId = "adb3425c-490f-4558-9487-8f8940d2925b";
      oauthSecretFile = config.sops.secrets.buildbot-oauth-secret-file.path;
      webhookSecretFile = config.sops.secrets.buildbot-webhook-secret-file.path;
      tokenFile = config.sops.secrets.buildbot-token-file.path;
      topic = "buildbot-clan";
    };

    jobReportLimit = 0;
    # optional nix-eval-jobs settings
    evalWorkerCount = 50; # limit number of concurrent evaluations
    evalMaxMemorySize = 4096; # limit memory usage per evaluation
  };

  # Optional: Enable acme/TLS in nginx (recommended)
  services.nginx.virtualHosts.${config.services.buildbot-nix.master.domain} = {
    forceSSL = true;
    enableACME = true;
  };

  services.buildbot-nix.worker = {
    enable = true;
    workerPasswordFile = config.sops.secrets.buildbot-worker-password-file.path;
  };

  sops.secrets.buildbot-oauth-secret-file = { };
  sops.secrets.buildbot-workers-file = { };
  sops.secrets.buildbot-worker-password-file = { };
  sops.secrets.buildbot-token-file = { };
}
