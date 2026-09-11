{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.mailserver;

  mailDomain = "clan.lol";

  # A `stop` in the user's own script also ends the server-wide `after` script
  # that files `X-Spam: Yes` into Junk, so INBOX delivery wins.
  sieveFor =
    userCfg:
    let
      requires =
        lib.optional (userCfg.redirect != null) "copy" ++ lib.optional userCfg.noJunkFilter "fileinto";
      body =
        lib.optional (userCfg.redirect != null) ''redirect :copy "${userCfg.redirect}";''
        ++ lib.optionals userCfg.noJunkFilter [
          ''fileinto "INBOX";''
          "stop;"
        ];
    in
    if requires == [ ] then
      null
    else
      lib.concatStringsSep "\n" (
        [
          ''require ["${lib.concatStringsSep "\", \"" requires}"];''
          ""
        ]
        ++ body
      );

  unfilteredUsers = lib.attrNames (lib.filterAttrs (_: u: u.noJunkFilter) cfg.users);
  purgedUsers = lib.attrNames (lib.filterAttrs (_: u: u.purgeDownloaded) cfg.users);

  doveadm = lib.getExe' config.services.dovecot2.package "doveadm";

  mailPurge = pkgs.writeShellScript "mail-purge" ''
    set -eu
    ${lib.concatMapStrings (username: ''
      # POP3 only ever shows INBOX, so anything filed into Junk before this was
      # enabled is invisible to the client. Unread it, then move it where it
      # belongs instead of expunging mail the user never got to see.
      ${doveadm} flags remove -u ${username}@${mailDomain} '\Seen' mailbox 'Junk*' all
      ${doveadm} move -u ${username}@${mailDomain} INBOX mailbox 'Junk*' all
      # POP3 RETR sets \Seen, so a downloaded message is a read message.
      ${doveadm} expunge -u ${username}@${mailDomain} mailbox '*' SEEN
      # Copies a client uploaded over IMAP after submitting via SMTP. Nothing
      # legitimately lives in these for a POP3 account, downloaded or not.
      ${doveadm} expunge -u ${username}@${mailDomain} mailbox 'Sent*' all
      ${doveadm} expunge -u ${username}@${mailDomain} mailbox 'Drafts*' all
      ${doveadm} expunge -u ${username}@${mailDomain} mailbox 'Trash*' all
    '') purgedUsers}
  '';
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
      w = {
        noJunkFilter = true;
        purgeDownloaded = true;
      };
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
      domains = [
        "clan.lol"
        "noreply.git.clan.lol"
      ];
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

      accounts = lib.mapAttrs' (
        username: userCfg:
        lib.nameValuePair "${username}@${mailDomain}" (
          {
            hashedPasswordFile =
              config.clan.core.vars.generators."${username}-mail".files."${username}-password-hash".path;
          }
          // lib.optionalAttrs (sieveFor userCfg != null) {
            sieveScript = sieveFor userCfg;
          }
          // lib.optionalAttrs (username == "gitea") {
            catchAll = [ "noreply.git.clan.lol" ];
          }
        )
      ) cfg.users;
    };

    # REMOVEME when rspamd stops segfaulting when using the PCRE JIT which
    # causes the mailserver to not accept any mail
    services.rspamd.overrides."options.inc".text = ''
      disable_pcre_jit = true;
    '';

    # Mail to these recipients skips rspamd entirely: no reject at 15, no
    # greylisting, no X-Spam or X-Spamd-Result header (extended_spam_headers is
    # on upstream, so nulling the actions alone would still tag every message),
    # and no history row. Matching on rcpt is deliberate: keyed on the
    # authenticated sender instead, want_spam would also skip dkim_signing and
    # outbound mail would leave unsigned. The match is per SMTP transaction, so
    # a message addressed to an unfiltered and a filtered mailbox at once
    # bypasses both.
    services.rspamd.locals."settings.conf" = lib.mkIf (unfilteredUsers != [ ]) {
      text = ''
        no_junk_filter {
          priority = high;
          rcpt = [${
            lib.concatMapStringsSep ", " (username: ''"${username}@${mailDomain}"'') unfilteredUsers
          }];
          want_spam = yes;
        }
      '';
    };

    # Outbound mail passes the milter for DKIM signing; without this rspamd would
    # keep sender, recipients and subject of every relayed message in redis.
    services.rspamd.locals."history_redis.conf".text = ''
      enabled = false;
    '';

    # if rspamd is down, still allow sending and receiving mail
    services.postfix.settings.main.milter_default_action = "accept";

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

    # Runs on activation and every five minutes afterwards, so these mailboxes
    # converge on "INBOX only, nothing retrieved" rather than the policy
    # applying to new mail alone.
    systemd.services.mail-purge = lib.mkIf (purgedUsers != [ ]) {
      description = "Move junk to the inbox, expunge downloaded and sent mail";
      wantedBy = [ "multi-user.target" ];
      after = [ "dovecot.service" ];
      requires = [ "dovecot.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = mailPurge;
      };
    };

    systemd.timers.mail-purge = lib.mkIf (purgedUsers != [ ]) {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/5";
        AccuracySec = "30s";
        Persistent = true;
      };
    };

    clan.core.vars.generators = lib.mapAttrs' (
      username: userCfg:
      lib.nameValuePair "${username}-mail" {
        files."${username}-password" = { };
        files."${username}-password-hash" = { };
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
