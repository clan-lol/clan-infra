{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "outline.${config.networking.fqdn}";
  idmDomain = config.services.kanidm.serverSettings.origin;
  clientId = "outline";
in
{
  imports = [ ../acme.nix ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "outline"
    ];

  clan.core.vars.generators.outline = {
    files.oidc-secret = {
      owner = config.services.outline.user;
      inherit (config.services.outline) group;
    };
    prompts.oidc-secret.persist = true;
  };

  # This group is a Kanidm builtin, but we need to specify it as
  # the NixOS module won't let us create a scope map referencing
  # it without declaring it first.
  services.kanidm.provision.groups.idm_all_persons = { };

  services.kanidm.provision.systems.oauth2.${clientId} = {
    displayName = "Outline";
    originUrl = "https://${domain}/auth/oidc.callback";
    originLanding = "https://${domain}";
    allowInsecureClientDisablePkce = true;
    scopeMaps.idm_all_persons = config.services.outline.oidcAuthentication.scopes;
  };

  services.outline = {
    enable = true;

    oidcAuthentication = {
      authUrl = "${idmDomain}/ui/oauth2";
      inherit clientId;
      scopes = [
        "openid"
        "email"
        "profile"
      ];
      clientSecretFile = config.clan.core.vars.generators.outline.files.oidc-secret.path;
      displayName = config.services.kanidm.serverSettings.domain;
      tokenUrl = "${idmDomain}/oauth2/token";
      userinfoUrl = "${idmDomain}/oauth2/openid/outline/userinfo";
    };

    publicUrl = "https://${domain}";
    storage.storageType = "local";
  };

  services.postgresql.package = pkgs.postgresql_16;

  services.nginx.virtualHosts."outline.${config.networking.fqdn}" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.outline.port}";
      recommendedProxySettings = true;
      proxyWebsockets = true;
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
