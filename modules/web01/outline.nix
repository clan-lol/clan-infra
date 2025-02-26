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
      clientId = "bd55e893-2720-4603-ac65-12229003147d";
      clientSecretFile = config.clan.core.vars.generators.outline.files.oidc-secret.path;
      displayName = "Gitea";
      tokenUrl = "https://git.clan.lol/login/oauth/access_token";
      userinfoUrl = "https://git.clan.lol/login/oauth/userinfo";
    };

    publicUrl = "http://outline.clan.lol";
    storage.storageType = "local";
  };

  services.nginx.virtualHosts."outline.clan.lol" = {
    forceSSL = true;
    enableACME = true;
    locations."/".extraConfig = ''
      proxy_pass http://127.0.0.1:3000;
    '';
  };
}
