{
  _class,
  lib,
  ...
}:
{
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  }
  # Run daily at 03:15
  // lib.optionalAttrs (_class == "nixos") { dates = [ "daily" ]; }
  // lib.optionalAttrs (_class == "darwin") {
    interval = [
      {
        Hour = 3;
        Minute = 15;
      }
    ];
  };
}
