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
