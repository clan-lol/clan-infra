{
  config,
  lib,
  pkgs,
  self,
  ...
}:
{
  services.nixbot = {
    enable = true;
    domain = "nixbot.clan.lol";

    # Keep buildbot-era status context names so existing branch protection
    # rules on Gitea keep matching the required checks.
    statusContextPrefix = "buildbot";

    admins = map (name: "gitea:${name}") (
      lib.mapAttrsToList (_: user: user.gitea.username) (
        lib.filterAttrs (
          _: user: user.isNormalUser && builtins.elem "wheel" user.extraGroups
        ) config.users.users
      )
      ++ [
        "brianmcgee"
      ]
    );

    buildSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];

    gitea = {
      enable = true;
      instanceUrl = "https://git.clan.lol";
      # OAuth2 application of the nixbot Gitea user,
      # redirect URI: https://nixbot.clan.lol/auth/gitea/callback
      oauthId = "03ce557a-cc87-44ea-9ed5-9bc598ae5eb7";
      oauthSecretFile = config.clan.core.vars.generators.nixbot.files."gitea-oauth-secret".path;
      tokenFile = config.clan.core.vars.generators.nixbot.files."gitea-token".path;
      # No topic-based import; projects are enabled through the web UI.
    };

    # match releases, e.g. 25.11
    branches.stableBranches.matchGlob = "^\d\d\.\d\d$";

    evalWorkerCount = 20;
    evalMaxMemorySize = 2096; # MiB per evaluation worker

    niks3 = {
      enable = true;
      serverUrl = "https://niks3.clan.lol";
      authTokenFile = config.clan.core.vars.generators.niks3-api-token.files."token".path;
      package = self.inputs.niks3.packages.${config.nixpkgs.hostPlatform.system}.niks3;
    };

    nginx.enableACME = true;
  };

  # Old CI URL still referenced from PRs, chat logs and bookmarks.
  services.nginx.virtualHosts."buildbot.clan.lol" = {
    forceSSL = true;
    enableACME = true;
    locations."/".return = "301 https://nixbot.clan.lol$request_uri";
  };

  clan.core.vars.generators.nixbot = {
    prompts."gitea-token" = {
      description = "Gitea API token for the nixbot user (repository read/write scope)";
      persist = true;
    };
    prompts."gitea-oauth-secret" = {
      description = "Client secret of the nixbot OAuth2 application in Gitea";
      persist = true;
    };
    files."gitea-token" = { };
    files."gitea-oauth-secret" = { };
    runtimeInputs = [ pkgs.coreutils ];
    script = ''
      cp "$prompts/gitea-token" "$out/gitea-token"
      cp "$prompts/gitea-oauth-secret" "$out/gitea-oauth-secret"
    '';
  };
}
