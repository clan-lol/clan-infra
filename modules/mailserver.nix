{ config, pkgs, ... }:
let
  mailPassword =
    { service }:
    {
      secret."${service}-password" = { };
      secret."${service}-password-hash" = { };
      generator.path = with pkgs; [
        coreutils
        xkcdpass
        mkpasswd
      ];
      generator.script = ''
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
      config.clan.core.facts.services.golem-mail.secret.golem-password-hash.path;
    loginAccounts."gitea@clan.lol".hashedPasswordFile =
      config.clan.core.facts.services.gitea-mail.secret.gitea-password-hash.path;
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

  clan.core.facts.services.golem-mail = mailPassword { service = "golem"; };
  clan.core.facts.services.gitea-mail = mailPassword { service = "gitea"; };
}
