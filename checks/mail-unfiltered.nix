# Guards the three promises made for accounts with `noJunkFilter` and
# `purgeDownloaded` (modules/mailserver.nix): nothing is filtered, nothing
# downloaded stays, and nothing sent is kept. The rspamd rule, the sieve script
# and the purge script are taken verbatim out of web01's evaluated config, so
# the test cannot drift from what actually ships.
#
# Needs KVM.
{
  self,
  inputs,
  pkgs,
}:
let
  web01 = self.nixosConfigurations.web01.config;

  tls =
    pkgs.runCommand "mail-test-tls"
      {
        nativeBuildInputs = [ pkgs.openssl ];
      }
      ''
        mkdir -p $out
        openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
          -subj /CN=mail.clan.lol -keyout $out/key.pem -out $out/cert.pem
      '';

  passwordFile =
    pkgs.runCommand "mail-test-password"
      {
        nativeBuildInputs = [ pkgs.mkpasswd ];
      }
      ''
        mkpasswd -s <<<"test-only" > $out
      '';

  # GTUBE cannot serve as the probe: rspamd matches it while parsing the
  # message and sets a reject pre-result, which no settings rule can undo.
  # A plain scored symbol is what real spam goes through.
  probeRule = pkgs.writeText "probe.lua" ''
    rspamd_config:register_symbol({
      name = 'PROBE_SPAM',
      type = 'callback',
      callback = function(task)
        local hdr = task:get_header('X-Probe')
        return hdr == 'spam'
      end,
    })
    rspamd_config:set_metric_symbol({
      name = 'PROBE_SPAM',
      score = 100.0,
      description = 'test-only probe symbol',
    })
  '';

  # Receives whatever the server relays and keeps it, so "the message departed"
  # is an observation rather than an assumption.
  sinkPython = pkgs.python3.withPackages (p: [ p.aiosmtpd ]);
  sinkScript = pkgs.writeScript "mail-sink" ''
    #!${sinkPython.interpreter}
    import time
    from aiosmtpd.controller import Controller


    class Store:
        async def handle_DATA(self, server, session, envelope):
            with open("/var/lib/mail-sink/received", "ab") as fh:
                fh.write(envelope.content)
            return "250 Message accepted"


    Controller(Store(), hostname="0.0.0.0", port=25).start()
    while True:
        time.sleep(3600)
  '';

  gtube = "XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X";

  mailPurge = web01.systemd.services.mail-purge.serviceConfig.ExecStart;
in
{
  name = "mail-unfiltered";

  nodes = {
    server =
      {
        nodes,
        pkgs,
        ...
      }:
      {
        imports = [ inputs.nixos-mailserver.nixosModules.mailserver ];

        virtualisation.memorySize = 2048;

        mailserver = {
          enable = true;
          inherit (web01.mailserver) stateVersion;
          fqdn = "mail.clan.lol";
          domains = [ "clan.lol" ];
          enablePop3Ssl = true;
          # As on web01: the full text index is another place a message body
          # could outlive its expunge, so the test exercises it.
          inherit (web01.mailserver) fullTextSearch;
          # As on web01, so postfix resolves through the node's own nameserver
          # rather than a local recursor with no route to the root servers.
          localDnsResolver = false;
          x509 = {
            certificateFile = "${tls}/cert.pem";
            privateKeyFile = "${tls}/key.pem";
          };
          accounts = {
            "infra@clan.lol".hashedPasswordFile = passwordFile;
            "w@clan.lol" = {
              hashedPasswordFile = passwordFile;
              inherit (web01.mailserver.accounts."w@clan.lol") sieveScript;
            };
          };
        };

        services.rspamd.localLuaRules = probeRule;

        services.rspamd.locals = {
          inherit (web01.services.rspamd.locals) "settings.conf" "history_redis.conf";
          # The test network has no recursor, and rspamd would otherwise spend
          # the whole delivery timeout waiting for SPF and DMARC lookups.
          "options.inc".text = ''
            dns {
              nameservers = ["127.0.0.1"];
              timeout = 0.0s;
              retransmits = 0;
            }
          '';
        };

        # A literal address, because the test network has no resolver: an MX
        # lookup for the sink's domain would never answer.
        services.postfix.settings.main.relayhost = [ "[${nodes.sink.networking.primaryIPAddress}]" ];
        networking.nameservers = [ nodes.sink.networking.primaryIPAddress ];

        environment.systemPackages = [ pkgs.redis ];
      };

    client =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.python3 ];
      };

    sink =
      { config, ... }:
      {
        systemd.services.mail-sink = {
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = sinkScript;
            StateDirectory = "mail-sink";
          };
        };

        # Postfix refuses a recipient whose domain does not resolve, so the
        # sink answers for its own domain.
        services.dnsmasq = {
          enable = true;
          settings.address = "/notexample.com/${config.networking.primaryIPAddress}";
        };

        networking.firewall = {
          allowedTCPPorts = [
            25
            53
          ];
          allowedUDPPorts = [ 53 ];
        };
      };
  };

  testScript =
    { nodes, ... }:
    let
      send = pkgs.writeScript "send-mail" ''
        #!${pkgs.python3.interpreter}
        import smtplib, sys

        rcpt, kind = sys.argv[1], sys.argv[2]
        probe = "X-Probe: spam\n" if kind == "spam" else ""
        msg = f"From: sender@notexample.com\nTo: {rcpt}\n{probe}Subject: probe\n\nhello\n"
        with smtplib.SMTP("${nodes.server.networking.primaryIPAddress}", 25) as smtp:
            smtp.sendmail("sender@notexample.com", [rcpt], msg)
      '';
      sendGtube = pkgs.writeScript "send-gtube" ''
        #!${pkgs.python3.interpreter}
        import smtplib

        msg = "From: sender@notexample.com\nTo: w@clan.lol\nSubject: probe\n\n${gtube}\n"
        with smtplib.SMTP("${nodes.server.networking.primaryIPAddress}", 25) as smtp:
            smtp.sendmail("sender@notexample.com", ["w@clan.lol"], msg)
      '';
      pop3Fetch = pkgs.writeScript "pop3-fetch" ''
        #!${pkgs.python3.interpreter}
        import poplib, ssl

        # Leave-on-server behaviour on purpose: no DELE, so the server side has
        # to be what removes the mail.
        pop = poplib.POP3_SSL(
            "${nodes.server.networking.primaryIPAddress}", 995, context=ssl._create_unverified_context()
        )
        pop.user("w@clan.lol")
        pop.pass_("test-only")
        count = len(pop.list()[1])
        for index in range(1, count + 1):
            pop.retr(index)
        pop.quit()
        print(count)
      '';
      # POP3 has no notion of a folder, so a listing is the client's whole view
      # of the account. No DELE and no RETR: this must not change any state.
      pop3List = pkgs.writeScript "pop3-list" ''
        #!${pkgs.python3.interpreter}
        import poplib, ssl

        pop = poplib.POP3_SSL(
            "${nodes.server.networking.primaryIPAddress}", 995, context=ssl._create_unverified_context()
        )
        pop.user("w@clan.lol")
        pop.pass_("test-only")
        print(len(pop.list()[1]))
        pop.quit()
      '';
      submit = pkgs.writeScript "submit-mail" ''
        #!${pkgs.python3.interpreter}
        import smtplib, ssl

        msg = "From: w@clan.lol\nTo: sink@notexample.com\nSubject: departing\n\nbye\n"
        with smtplib.SMTP_SSL(
            "${nodes.server.networking.primaryIPAddress}", 465, context=ssl._create_unverified_context()
        ) as smtp:
            smtp.login("w@clan.lol", "test-only")
            smtp.sendmail("w@clan.lol", ["sink@notexample.com"], msg)
      '';
    in
    ''
      start_all()
      server.wait_for_unit("postfix.service")
      server.wait_for_unit("dovecot.service")
      server.wait_for_unit("rspamd.service")
      server.wait_for_open_port(25)
      client.wait_for_unit("multi-user.target")
      sink.wait_for_unit("mail-sink.service")
      sink.wait_for_open_port(25)


      def count(user, mailbox, query="all"):
          out = server.succeed(f"doveadm search -u {user} mailbox {mailbox} {query} | wc -l")
          return int(out.strip())


      # doveadm reports the index view; the worry is a file left behind, so
      # count message files across every folder the account has.
      def files(user):
          local, domain = user.split("@")
          out = server.succeed(
              f"find /var/vmail/{domain}/{local} -type f"
              r" \( -path '*/cur/*' -o -path '*/new/*' \) | wc -l"
          )
          return int(out.strip())


      with subtest("the bypass rule is loaded and rspamd runs without its history"):
          server.succeed("rspamadm configtest")
          server.succeed("rspamadm configdump settings | grep -q want_spam")

      with subtest("a plain probe scores nothing for the bypassed recipient"):
          probe = "printf 'From: t@notexample.com\\nTo: %s\\nSubject: t\\n\\nhello\\n' | rspamc -r %s symbols"
          bypassed = server.succeed(probe % ("w@clan.lol", "w@clan.lol"))
          filtered = server.succeed(probe % ("infra@clan.lol", "infra@clan.lol"))
          assert "Score: 0.00" in bypassed, bypassed
          assert "Symbol:" not in bypassed, bypassed
          assert "Symbol:" in filtered, filtered

      with subtest("a 100-point message to a filtered mailbox is refused at SMTP"):
          client.fail("${send} infra@clan.lol spam >&2")
          assert count("infra@clan.lol", "INBOX") == 0
          assert count("infra@clan.lol", "Junk") == 0

      with subtest("the same message lands in the unfiltered mailbox's INBOX"):
          client.succeed("${send} w@clan.lol spam >&2")
          server.wait_until_succeeds(
              "doveadm search -u w@clan.lol mailbox INBOX all | grep -q .", timeout=30
          )
          assert count("w@clan.lol", "INBOX") == 1
          assert count("w@clan.lol", "Junk") == 0

      with subtest("no scanner headers are added for the unfiltered mailbox"):
          headers = server.succeed("doveadm fetch -u w@clan.lol hdr mailbox INBOX all").lower()
          for header in ["x-spam", "x-rspamd"]:
              assert header not in headers, headers

      with subtest("the sieve stop does not swallow ordinary mail"):
          client.succeed("${send} w@clan.lol ham >&2")
          server.wait_until_succeeds(
              "test $(doveadm search -u w@clan.lol mailbox INBOX all | wc -l) -eq 2", timeout=30
          )
          assert count("w@clan.lol", "Junk") == 0

      with subtest("a POP3 listing sees every message in the account"):
          server.wait_for_open_port(995)
          assert int(client.succeed("${pop3List}").strip()) == count("w@clan.lol", "INBOX")

      # Documented exception, pinned so an upstream change surfaces here: the
      # GTUBE test pattern is a parse-time pre-result, immune to want_spam.
      with subtest("a literal GTUBE pattern is still refused"):
          client.fail("${sendGtube} >&2")
          assert count("w@clan.lol", "INBOX") == 2

      with subtest("mail already sitting in Junk drains back into INBOX"):
          server.succeed("doveadm mailbox create -u w@clan.lol Junk || true")
          server.succeed("doveadm move -u w@clan.lol Junk mailbox INBOX all")
          assert count("w@clan.lol", "INBOX") == 0
          assert count("w@clan.lol", "Junk") == 2
          # Junk mail that someone already opened must not be read as
          # "downloaded" and destroyed by the expunge in the same run.
          server.succeed("doveadm flags add -u w@clan.lol '\\Seen' mailbox Junk all")
          server.succeed("${mailPurge}")
          assert count("w@clan.lol", "INBOX") == 2
          assert count("w@clan.lol", "Junk") == 0
          # Rescued mail has to stay fetchable: unread, so the expunge in the
          # same pass cannot mistake it for something already downloaded.
          assert count("w@clan.lol", "INBOX", "unseen") == 2

      with subtest("POP3-retrieved mail is expunged even without a client DELE"):
          assert client.succeed("${pop3Fetch}").strip() == "2"
          assert count("w@clan.lol", "INBOX") == 2
          server.succeed("${mailPurge}")
          assert count("w@clan.lol", "INBOX") == 0
          assert files("w@clan.lol") == 0

      with subtest("mail that has not been downloaded is left alone"):
          client.succeed("${send} w@clan.lol ham >&2")
          server.wait_until_succeeds(
              "doveadm search -u w@clan.lol mailbox INBOX all | grep -q .", timeout=30
          )
          server.succeed("${mailPurge}")
          assert count("w@clan.lol", "INBOX") == 1
          assert files("w@clan.lol") == 1

      with subtest("Sent and Drafts copies left by an IMAP client are purged"):
          for mailbox in ["Sent", "Drafts"]:
              server.succeed(f"doveadm mailbox create -u w@clan.lol {mailbox} || true")
              server.succeed(
                  "printf 'From: w@clan.lol\\nTo: someone@notexample.com\\nSubject: outgoing\\n\\nbye\\n'"
                  f" | doveadm save -u w@clan.lol -m {mailbox}"
              )
              assert count("w@clan.lol", mailbox) == 1
          server.succeed("${mailPurge}")
          assert count("w@clan.lol", "Sent") == 0
          assert count("w@clan.lol", "Drafts") == 0
          # The undownloaded INBOX message from the previous subtest survives.
          assert count("w@clan.lol", "INBOX") == 1

      with subtest("a submitted message departs and leaves nothing behind"):
          server.wait_for_open_port(465)
          before = files("w@clan.lol")
          client.succeed("${submit} >&2")
          sink.wait_until_succeeds(
              "grep -q 'Subject: departing' /var/lib/mail-sink/received", timeout=60
          )
          server.wait_until_succeeds("mailq | grep -q 'Mail queue is empty'", timeout=60)
          server.succeed("${mailPurge}")
          server.fail("doveadm fetch -u w@clan.lol text mailbox '*' all | grep -q departing")
          assert files("w@clan.lol") == before
          # Both checks below assert an absence, so each is preceded by the
          # positive case: without it a typo would pass forever.
          server.succeed(
              "printf 'From: w@clan.lol\\nSubject: departing\\n\\nbye\\n'"
              " | doveadm save -u w@clan.lol -m Sent"
          )
          server.succeed("doveadm fetch -u w@clan.lol text mailbox '*' all | grep -q departing")
          server.succeed("${mailPurge}")
          server.fail("doveadm fetch -u w@clan.lol text mailbox '*' all | grep -q departing")
          assert files("w@clan.lol") == before

          def history():
              return server.succeed(
                  "redis-cli -s /run/redis-rspamd/redis.sock --scan --pattern 'rs_history*'"
              ).strip()

          server.succeed("redis-cli -s /run/redis-rspamd/redis.sock set rs_history_probe x")
          assert history() == "rs_history_probe", history()
          server.succeed("redis-cli -s /run/redis-rspamd/redis.sock del rs_history_probe")
          assert history() == "", history()
    '';
}
