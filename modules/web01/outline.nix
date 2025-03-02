{
  config,
  lib,
  ...
}:
{

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "outline"
    ];

  clan.core.vars.generators.outline = {
    files.oidc-secret.owner = "outline";
    prompts.oidc-secret.persist = true;
  };

  services.outline = {
    enable = true;

    oidcAuthentication = {
      authUrl = "https://git.clan.lol/login/oauth/authorize";
      clientId = "9df8407c-f03d-4f69-a31f-311df2789b8a";
      clientSecretFile = config.clan.core.vars.generators.outline.files.oidc-secret.path;
      displayName = "Gitea";
      tokenUrl = "https://git.clan.lol/login/oauth/access_token";
      userinfoUrl = "https://git.clan.lol/login/oauth/userinfo";
    };

    publicUrl = "https://outline.clan.lol";
    storage.storageType = "local";
  };

  services.nginx.virtualHosts."outline.clan.lol" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://localhost:3000";
      recommendedProxySettings = true;
      proxyWebsockets = true;
    };
  };
}
