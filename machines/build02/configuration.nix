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

  environment.etc."nix-darwin".source = "${config.users.users.admin.home}/.config/nix-darwin";

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

  users.users.buildbot = {
    uid = 503;
    home = "/var/lib/buildbot";
    createHome = true;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      self.nixosConfigurations.web01.config.clan.core.vars.generators.openssh.files."ssh.id_ed25519.pub".value
    ];
  };

  nix.settings.trusted-users = [
    "buildbot"
    "root"
  ];

  users.knownUsers = [
    "admin"
    "buildbot"
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
