{ config, pkgs, ... }:
let
  mailPassword =
    { service }:
    {
      files."${service}-password" = { };
      files."${service}-password-hash" = { };
      migrateFact = "${service}-mail";
      runtimeInputs = with pkgs; [
        coreutils
        xkcdpass
        mkpasswd
      ];
      script = ''
        xkcdpass -n 4 -d - > $out/${service}-password
        cat $out/${service}-password | mkpasswd -s -m bcrypt > $out/${service}-password-hash
      '';
    };
in
{
  imports = [
    ./acme.nix
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

    loginAccounts."golem@clan.lol".hashedPasswordFile =
      config.clan.core.vars.generators.golem-mail.files.golem-password-hash.path;

    loginAccounts."w@clan.lol".hashedPasswordFile =
      config.clan.core.vars.generators.w-mail.files.w-password-hash.path;

    loginAccounts."chris@clan.lol".hashedPasswordFile =
      config.clan.core.vars.generators.chris-mail.files.chris-password-hash.path;

    loginAccounts."gitea@clan.lol".hashedPasswordFile =
      config.clan.core.vars.generators.gitea-mail.files.gitea-password-hash.path;

    loginAccounts."kiran@clan.lol".hashedPasswordFile =
      config.clan.core.vars.generators.kiran-mail.files.kiran-password-hash.path;

    loginAccounts."timo@clan.lol".hashedPasswordFile =
      config.clan.core.vars.generators.timo-mail.files.timo-password-hash.path;
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

  clan.core.vars.generators.golem-mail = mailPassword { service = "golem"; };
  clan.core.vars.generators.w-mail = mailPassword { service = "w"; };
  clan.core.vars.generators.gitea-mail = mailPassword { service = "gitea"; };

  clan.core.vars.generators.chris-mail = mailPassword { service = "chris"; };
  clan.core.vars.generators.kiran-mail = mailPassword { service = "kiran"; };
  clan.core.vars.generators.timo-mail = mailPassword { service = "timo"; };
}
