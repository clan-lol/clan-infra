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
    files.secret-file = { };
    dependencies = [ "nextcloud-mail" ];
    runtimeInputs = [
      pkgs.coreutils
      pkgs.xkcdpass
      pkgs.jq
    ];
    script = ''
      xkcdpass --numwords 4 --random-delimiters --valid-delimiters='1234567890!@#$%^&*()-_+=,.<>/?' --case random | tr -d "\n" > $out/admin-password
      jq -n --rawfile pass "$in/nextcloud-mail/nextcloud-password" '{mail_smtppassword: $pass | rtrimstr("\n")}' > $out/secret-file
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
    inherit (config.services.nextcloud.package.packages.apps)
      calendar
      contacts
      user_oidc
      ;
  };
  services.nextcloud.appstoreEnable = false;

  systemd.services.nextcloud-setup.script =
    let
      occ = lib.getExe config.services.nextcloud.occ;
    in
    lib.mkAfter ''
      # As the `user_oidc:provider` doesn't support updating the values after creation
      # we want to delete the provider first
      ${occ} user_oidc:provider:delete Gitea --force

      providerFlags=(
        --scope="openid email profile groups"
        --clientid=${lib.escapeShellArg config.clan.core.vars.generators.nextcloud-oidc.files.client-id.value}
        # We don't need a client secret because we use PKCE however the `user_oidc:provider` command
        # expects us to always pass a client secret.
        --clientsecret=""
        --discoveryuri="https://git.clan.lol/.well-known/openid-configuration"
        --unique-uid=0
        --mapping-uid=preferred_username
        --group-provisioning=1
        --group-whitelist-regex='/^clan:(owners|nextcloud)$/'
        --group-restrict-login-to-whitelist=1
        --mapping-groups=groups
        --no-interaction
      )

      ${occ} user_oidc:provider Gitea "''${providerFlags[@]}"

      # Force all users to log in through Gitea, to log in as the admin account you can go to:
      # https://nextcloud.clan.lol/login?direct=1&user=admin
      ${occ} config:app:set --value=0 user_oidc allow_multiple_user_backends

      ${occ} app:disable photos
    '';
  services.nextcloud.settings.user_oidc.use_pkce = true;

  services.nextcloud.settings = {
    mail_smtpmode = "smtp";
    mail_smtphost = "mail.clan.lol";
    mail_smtpport = 587;
    mail_smtpauth = true;
    mail_smtpname = "nextcloud@clan.lol";
    mail_domain = "clan.lol";
    mail_from_address = "nextcloud";
  };

  services.nextcloud.secretFile = config.clan.core.vars.generators.nextcloud.files.secret-file.path;

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
