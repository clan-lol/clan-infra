{
  config,
  pkgs,
  lib,
  ...
}:
let
  hostname = "nextcloud.clan.lol";
in
{
  clan.core.vars.generators.nextcloud = {
    files.admin-password = { };
    runtimeInputs = [
      pkgs.coreutils
      pkgs.xkcdpass
    ];
    script = ''
      xkcdpass --numwords 4 --random-delimiters --valid-delimiters='1234567890!@#$%^&*()-_+=,.<>/?' --case random | tr -d "\n" > $out/admin-password
    '';
  };

  clan.core.vars.generators.nextcloud-oidc = {
    prompts.client-id.persist = true;
    files.client-id.secret = false;
    files.client-id.deploy = false;
  };

  services.nextcloud.enable = true;
  services.nextcloud.package = pkgs.nextcloud32;
  services.nextcloud.hostName = hostname;
  services.nextcloud.https = true;
  services.nextcloud.database.createLocally = true;
  services.nextcloud.extraApps = {
    inherit (config.services.nextcloud.package.packages.apps) calendar user_oidc;
  };
  services.nextcloud.appstoreEnable = false;

  # We don't need a client secret because we use PKCE
  # however the `user_oidc:provider` command expects us
  # to always pass a client secret.
  systemd.services.nextcloud-setup.script = lib.mkAfter ''
    ${lib.getExe config.services.nextcloud.occ} user_oidc:provider:delete Gitea --force
    ${lib.getExe config.services.nextcloud.occ} user_oidc:provider Gitea \
      --scope="openid email profile groups" \
      --clientid=${lib.escapeShellArg config.clan.core.vars.generators.nextcloud-oidc.files.client-id.value} \
      --clientsecret="" \
      --discoveryuri="https://git.clan.lol/.well-known/openid-configuration" \
      --group-provisioning=1 \
      --group-whitelist-regex='/^clan:(owners|nextcloud)$/' \
      --group-restrict-login-to-whitelist=1 \
      --no-interaction
  '';
  services.nextcloud.settings.user_oidc.use_pkce = true;

  services.nextcloud.config = {
    dbtype = "pgsql";
    adminuser = "admin";
    adminpassFile = config.clan.core.vars.generators.nextcloud.files.admin-password.path;
  };

  services.nginx.virtualHosts.${hostname} = {
    forceSSL = true;
    enableACME = true;
  };
}
