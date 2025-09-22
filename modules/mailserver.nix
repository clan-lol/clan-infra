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
  imports = [
    ./acme.nix
  ];

  options.services.mailserver.users = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "List of usernames to create mail accounts for @clan.lol";
    example = [
      "alice"
      "bob"
    ];
  };

  config = {
    services.mailserver.users = [
      "golem"
      "w"
      "chris"
      "gitea"
      "kiran"
      "timo"
      "joerg"
    ];

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

      loginAccounts = lib.listToAttrs (
        map (user: {
          name = "${user}@clan.lol";
          value.hashedPasswordFile =
            config.clan.core.vars.generators."${user}-mail".files."${user}-password-hash".path;
        }) cfg.users
      );
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

    clan.core.vars.generators = lib.listToAttrs (
      map (user: {
        name = "${user}-mail";
        value = {
          files."${user}-password" = { };
          files."${user}-password-hash" = { };
          migrateFact = "${user}-mail";
          runtimeInputs = with pkgs; [
            coreutils
            xkcdpass
            mkpasswd
          ];
          script = ''
            xkcdpass -n 4 -d - > $out/${user}-password
            cat $out/${user}-password | mkpasswd -s -m bcrypt > $out/${user}-password-hash
          '';
        };
      }) cfg.users
    );
  };
}
