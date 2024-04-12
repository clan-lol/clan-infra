{ config, pkgs, self, ... }: {
  security.acme.defaults.email = "admins@clan.lol";
  security.acme.acceptTerms = true;

  # www user to push website artifacts via ssh
  users.users.www = {
    openssh.authorizedKeys.keys =
      config.users.users.root.openssh.authorizedKeys.keys
      ++ [
        # ssh-homepage-key
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMxZ3Av30M6Sh6NU1mnCskB16bYtNP8vskc/+ud0AU1C ssh-homepage-key"
      ];
    isSystemUser = true;
    shell = "/run/current-system/sw/bin/bash";
    group = "www";
  };
  users.groups.www = { };

  # ensure /var/www can be accessed by nginx and www user
  systemd.tmpfiles.rules = [
    "d /var/www 0755 www nginx"
  ];

  services.nginx = {
    virtualHosts."clan.lol" = {
      forceSSL = true;
      enableACME = true;
      # to be deployed via rsync
      root = "/var/www/clan.lol";
      extraConfig = ''
        charset utf-8;
        source_charset utf-8;
      '';

      # Make sure to expire the cache after 1 hour
      locations."/".extraConfig = ''
        add_header Cache-Control "public, max-age=3600";
      '';
      locations."/thaigersprint".return = "307 https://pad.lassul.us/s/clan-thaigersprint";
    };

    virtualHosts."docs.clan.lol" = {
      forceSSL = true;
      enableACME = true;
      # to be deployed via rsync
      root = "/var/www/docs.clan.lol";
      extraConfig = ''
        charset utf-8;
        source_charset utf-8;
      '';

      # Make sure to expire the cache after 1 hour
      locations."/".extraConfig = ''
        add_header Cache-Control "public, max-age=3600";
      '';
      locations."/docs".return = "301 https://docs.clan.lol";
    };

    virtualHosts."www.clan.lol" = {
      forceSSL = true;
      enableACME = true;
      globalRedirect = "clan.lol";
    };
  };
}
