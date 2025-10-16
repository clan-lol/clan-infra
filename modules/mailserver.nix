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
  ];

  config = {
    services.mailserver.users = {
      golem = { };
      w = { };
      chris = { };
      gitea = { };
      kiran = {
        redirect = "kiran.lenk99@googlemail.com";
      };
      nextcloud = { };
      timo = { };
      joerg = {
        redirect = "joerg.clan@thalheim.io";
      };
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

    mailserver = {
      enable = true;
      fqdn = "mail.clan.lol";
      domains = [ "clan.lol" ];
      enablePop3 = true;
      enableImap = true;

      certificateScheme = "acme-nginx";
      # kresd sucks unfortunally (fails when one NS server is not working, instead of trying other ones)
      localDnsResolver = false;

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
