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
        xkcdpass -n 4 -d - > $secrets/${service}-password
        cat $secrets/${service}-password | mkpasswd -s -m bcrypt > $secrets/${service}-password-hash
      '';
    };
in
{
  mailserver = {
    enable = true;
    fqdn = "mail.clan.lol";
    domains = [ "clan.lol" ];
    enablePop3 = true;
    certificateScheme = "acme-nginx";
    # kresd sucks unfortunally (fails when one NS server is not working, instead of trying other ones)
    localDnsResolver = false;

    loginAccounts."golem@clan.lol".hashedPasswordFile =
      config.clan.core.vars.generators.golem-mail.files.golem-password-hash.path;

    loginAccounts."w@clan.lol".hashedPasswordFile =
      config.clan.core.vars.generators.w-mail.files.w-password-hash.path;

    loginAccounts."gitea@clan.lol".hashedPasswordFile =
      config.clan.core.vars.generators.gitea-mail.files.gitea-password-hash.path;
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

  security.acme.acceptTerms = true;

  clan.core.vars.generators.golem-mail = mailPassword { service = "golem"; };
  clan.core.vars.generators.w-mail = mailPassword { service = "w"; };
  clan.core.vars.generators.gitea-mail = mailPassword { service = "gitea"; };
}
