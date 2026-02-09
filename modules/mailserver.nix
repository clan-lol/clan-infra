{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.mailserver;
in
{
  # To generate login instructions for a user, run:
  # ./scripts/generate-mail-instructions.sh <username>
  imports = [
    ./acme.nix
    ./mailserver-users.nix
    {
      clan.core.vars.generators.postsrsd = {
        files.secret = { };
        runtimeInputs = with pkgs; [
          coreutils
        ];
        script = ''
          dd if=/dev/random bs=18 count=1 status=none | base64 > $out/secret
        '';
      };
    }
  ];

  config = {
    services.mailserver.users = {
      golem = { };
      w = { };
      chris = { };
      gitea = { };
      pass = { };
      kiran = {
        redirect = "kiran.lenk99@googlemail.com";
      };
      nextcloud = { };
      timo = { };
      joerg = {
        redirect = "joerg.clan@thalheim.io";
      };
      infra = { };
      enzime = {
        redirect = "fine.wolf8996@fastmail.com";
      };
      hgl = { };
    };

    services.automx2.enable = true;
    services.automx2.domain = "clan.lol";
    services.automx2.settings = {
      provider = "Clan.lol";
      domains = [ "clan.lol" ];
      servers = [
        {
          type = "imap";
          name = "mail.clan.lol";
        }
        {
          type = "smtp";
          name = "mail.clan.lol";
        }
      ];
    };

    # Setup ACME certificate for mail.clan.lol via nginx
    services.nginx.virtualHosts."mail.clan.lol" = {
      enableACME = true;
      forceSSL = true;
      # Only allow using this subdomain for ACME http-01 challenge
      locations."/".return = "404";
    };

    # Allow mail services to read the ACME certificates
    users.groups.acme.members = [
      "nginx"
      "postfix"
      "dovecot2"
    ];

    mailserver = {
      enable = true;
      fqdn = "mail.clan.lol";
      domains = [ "clan.lol" ];
      enablePop3Ssl = true;

      # Disable these once there are no more clients using them as they're insecure
      enablePop3 = true;
      enableImap = true;
      # Re-enable STARTTLS on port 587 (disabled by default in 25.11 per RFC 8314 3.3)
      # Needed until all clients migrate to SMTPS on port 465
      enableSubmission = true;

      x509.useACMEHost = "mail.clan.lol";
      # kresd sucks unfortunally (fails when one NS server is not working, instead of trying other ones)
      localDnsResolver = false;

      # Necessary for forwarding emails
      srs.enable = true;

      fullTextSearch.enable = true;

      loginAccounts = lib.mapAttrs' (
        username: userCfg:
        lib.nameValuePair "${username}@clan.lol" (
          {
            hashedPasswordFile =
              config.clan.core.vars.generators."${username}-mail".files."${username}-password-hash".path;
          }
          // lib.optionalAttrs (userCfg.redirect != null) {
            sieveScript = ''
              require ["copy"];
              redirect :copy "${userCfg.redirect}";
            '';
          }
        )
      ) cfg.users;
    };

    services.postsrsd.secretsFile = config.clan.core.vars.generators.postsrsd.files.secret.path;

    services.unbound = {
      enable = true;
      settings.server = {
        prefetch = "yes";
        prefetch-key = true;
        qname-minimisation = true;
        # Too many broken dnssec setups even at big companies such as amazon.
        # Breaks my email setup. Better rely on tls for security.
        val-permissive-mode = "yes";
      };
    };

    # use local unbound as dns resolver
    networking.nameservers = [ "127.0.0.1" ];

    clan.core.vars.generators = lib.mapAttrs' (
      username: userCfg:
      lib.nameValuePair "${username}-mail" {
        files."${username}-password" = { };
        files."${username}-password-hash" = { };
        migrateFact = "${username}-mail";
        runtimeInputs = with pkgs; [
          coreutils
          xkcdpass
          mkpasswd
        ];
        script = ''
          xkcdpass -n 4 -d - > $out/${username}-password
          cat $out/${username}-password | mkpasswd -s -m bcrypt > $out/${username}-password-hash
        '';
      }
    ) cfg.users;
  };
}
