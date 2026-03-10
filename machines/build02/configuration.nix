{
  config,
  self,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    self.darwinModules.build02
  ];

  services.tailscale.enable = true;

  nix.settings.experimental-features = lib.mkForce [
    "nix-command"
    "flakes"
    "fetch-closure"
    "recursive-nix"
    "configurable-impure-env"
    # "ca-derivations" # breaks devshells
    "impure-derivations"
    "blake3-hashes"
    "nix-command"
    "flakes"
  ];

  users.users.luishebendanz = {
    uid = 501;
    shell = pkgs.zsh;
  };

  users.users.admin = {
    uid = 502;
    home = "/Users/admin";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
  };

  users.knownUsers = [
    "admin"
    "luishebendanz"
  ];

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
