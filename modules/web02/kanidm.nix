{ config, pkgs, ... }:
let
  domain = "idm.${config.networking.fqdn}";
  certs = config.security.acme.certs."${domain}";
in
{
  imports = [ ../acme.nix ];

  clan.core.vars.generators.kanidm = {
    files.admin-password = {
      owner = config.systemd.services.kanidm.serviceConfig.User;
      group = config.systemd.services.kanidm.serviceConfig.Group;
    };
    files.idm-admin-password = {
      owner = config.systemd.services.kanidm.serviceConfig.User;
      group = config.systemd.services.kanidm.serviceConfig.Group;
    };
    runtimeInputs = [ pkgs.xkcdpass ];
    script = ''
      xkcdpass --numwords 3 --delimiter - --count 1 | tr -d "\n" > "$out"/admin-password
      xkcdpass --numwords 3 --delimiter - --count 1 | tr -d "\n" > "$out"/idm-admin-password
    '';
  };

  services.kanidm = {
    package = pkgs.kanidmWithSecretProvisioning_1_7;
    enableServer = true;
    serverSettings = {
      inherit domain;
      origin = "https://${domain}";
      tls_chain = "${certs.directory}/fullchain.pem";
      tls_key = "${certs.directory}/key.pem";
    };
    provision = {
      enable = true;
      adminPasswordFile = config.clan.core.vars.generators.kanidm.files.admin-password.path;
      idmAdminPasswordFile = config.clan.core.vars.generators.kanidm.files.idm-admin-password.path;
      # Don't declare any users here as that may cause existing users to get wiped
    };
  };

  systemd.services.kanidm = {
    after = [ "acme-selfsigned-internal.${domain}.target" ];
    serviceConfig = {
      SupplementaryGroups = [ certs.group ];
    };
  };

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "https://${config.services.kanidm.serverSettings.bindaddress}";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
