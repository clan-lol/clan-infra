# `nix run .#spam-test`: send a message that must be refused to a filtered
# mailbox and accepted by every mailbox that has filtering off, and report what
# mail.clan.lol answered. The addresses come from web01's evaluated config, so
# the probe cannot target a mailbox that no longer exists.
{
  lib,
  swaks,
  writeShellApplication,
  fqdn,
  control,
  unfiltered,
}:
assert lib.assertMsg (
  unfiltered != [ ]
) "no mailbox has noJunkFilter set, so there is nothing to probe";
assert lib.assertMsg (
  !lib.elem control unfiltered
) "the control mailbox ${control} has filtering off, so it cannot be a control";
writeShellApplication {
  name = "spam-test";
  runtimeInputs = [ swaks ];
  runtimeEnv = {
    SERVER = fqdn;
    PORT = "25";
    FROM = "service@paypal.com";
    CONTROL = control;
    UNFILTERED = lib.concatStringsSep " " unfiltered;
    MESSAGE = builtins.path {
      path = ./spam-test.eml;
      name = "spam-test.eml";
    };
  };
  text = builtins.readFile ./spam-test.sh;
}
