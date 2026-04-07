{
  _class,
  lib,
  pkgs,
  ...
}:
{
  nix.package = pkgs.nixVersions.latest.appendPatches [
    # https://github.com/Enzime/nix/commits/patch-oom
    (pkgs.fetchpatch {
      name = "fix-gnu-patch-oom-on-macos.patch";
      url = "https://github.com/NixOS/nix/commit/6959b5ce7a2ee01df0a3bc2b6aae8ba5473e0496.patch";
      hash = "sha256-IA+HXKvWShBEnu38W7o1YhSWRK5ntWpFUFi2We3I7Io=";
    })
  ];

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
