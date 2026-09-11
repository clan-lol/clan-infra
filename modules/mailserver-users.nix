{ lib, ... }:
let
  userOpts =
    { name, ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Username (without domain)";
        };

        redirect = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Email address to redirect/forward mail to (creates a copy)";
          example = "backup@example.com";
        };

        noJunkFilter = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Deliver every message to INBOX. Disables the server-wide junk sieve for
            this account and stops rspamd from rejecting or greylisting mail to it.
            Malware is delivered too, since nothing is filtered.
          '';
        };

        purgeDownloaded = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Periodically expunge read messages (POP3 RETR sets \Seen) and everything
            in Sent, Junk and Trash, so nothing accumulates on the server.
          '';
        };
      };
    };
in
{
  options.services.mailserver.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule userOpts);
    default = { };
    description = "Mail user accounts configuration";
    example = lib.literalExpression ''
      {
        alice = { };
        bob = {
          redirect = "bob@other-domain.com";
        };
      }
    '';
  };
}
