{ config
, pkgs
, inputs
, ...
}:
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
  mailserver = rec {
    enable = true;
    fqdn = "mail.clan.lol";
    domains = [ "clan.lol" ];

    loginAccounts."golem@clan.lol".hashedPasswordFile =
      config.clanCore.facts.services.golem-mail.secret.golem-password-hash.path;
    loginAccounts."gitea@clan.lol".hashedPasswordFile =
      config.clanCore.facts.services.gitea-mail.secret.gitea-password-hash.path;
  };

  security.acme.acceptTerms = true;

  clanCore.facts.services.golem-mail = mailPassword { service = "golem"; };
  clanCore.facts.services.gitea-mail = mailPassword { service = "gitea"; };
}
