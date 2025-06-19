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

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  nix.settings.sandbox = true;

  services.openssh.enable = true;

  services.tailscale.enable = true;

  users.users.root = {
    uid = 0;
    # Necessary because nix-darwin doesn't correctly set the PATH
    # for sh or bash so `ssh root@clan-mac-mini nix-daemon --version`
    # will fail with `command not found`
    shell = lib.mkForce pkgs.zsh;
  };

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

  nix.settings.trusted-users = [
    "root"
  ];

  users.knownUsers = [
    "admin"
    "luishebendanz"
    "root"
  ];

  clan.core.networking.targetHost = "root@build02";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
