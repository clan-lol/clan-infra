{ config, ... }:
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

    gitea = {
      enable = true;
      instanceUrl = "https://git.clan.lol";
      oauthSecretFile = config.sops.secrets.oauth-secret-file.path;
      oauthId = "adb3425c-490f-4558-9487-8f8940d2925b";
      topic = "buildbot-clan";
    };

    # optional nix-eval-jobs settings
    evalWorkerCount = 10; # limit number of concurrent evaluations
    evalMaxMemorySize = "4096"; # limit memory usage per evaluation
  };

  # Optional: Enable acme/TLS in nginx (recommended)
  services.nginx.virtualHosts.${config.services.buildbot-nix.master.domain} = {
    forceSSL = true;
    useACME = true;
  };

  services.buildbot-nix.worker = {
    enable = true;
    workerPasswordFile = config.sops.secrets.buildbot-worker-password-file.path;
  };

  sops.secrets.oauth-secret-file = { };
  sops.secrets.workers-file = { };
  sops.secrets.worker-password-file = { };
}
