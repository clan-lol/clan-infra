{
  config,
  pkgs,
  ...
}:
{
  # PostgreSQL database for gitea-mq
  services.postgresql.ensureDatabases = [ "gitea-mq" ];
  services.postgresql.ensureUsers = [
    {
      name = "gitea-mq";
      ensureDBOwnership = true;
    }
  ];

  services.gitea-mq = {
    enable = true;
    giteaUrl = "https://git.clan.lol";
    giteaTokenFile = config.clan.core.vars.generators.gitea-mq.files."gitea-token".path;
    topic = "merge-queue";
    databaseUrl = "postgres:///gitea-mq?host=/run/postgresql";
    webhookSecretFile = config.clan.core.vars.generators.gitea-mq.files."webhook-secret".path;
    listenAddr = "127.0.0.1:8092";
    externalUrl = "https://mq.clan.lol";
  };

  # Clan vars: prompt for the Gitea API token, generate the webhook secret
  clan.core.vars.generators.gitea-mq = {
    prompts."gitea-token" = {
      description = "Gitea API token for gitea-mq (needs repo read/write scope)";
      persist = true;
    };
    files."gitea-token" = { };
    files."webhook-secret" = { };
    runtimeInputs = with pkgs; [
      coreutils
      openssl
    ];
    script = ''
      cp "$prompts/gitea-token" "$out/gitea-token"
      openssl rand -hex 32 > "$out/webhook-secret"
    '';
  };

  services.nginx.virtualHosts."mq.clan.lol" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8092";
    };
  };
}
