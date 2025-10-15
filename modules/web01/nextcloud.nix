{
  config,
  pkgs,
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

  services.nextcloud.enable = true;
  services.nextcloud.package = pkgs.nextcloud32;
  services.nextcloud.hostName = hostname;
  services.nextcloud.https = true;
  services.nextcloud.database.createLocally = true;
  services.nextcloud.extraApps = {
    inherit (config.services.nextcloud.package.packages.apps) calendar user_oidc;
  };
  services.nextcloud.appstoreEnable = false;

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
