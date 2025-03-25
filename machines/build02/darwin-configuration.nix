{
  config,
  self,
  pkgs,
  ...
}:
{
  imports = [ self.darwinModules.deploy ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

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
    shell = "/bin/zsh";
    # Necessary for remote deployment as `admin` is not a trusted user
    # so copying untrusted inputs will fail
    openssh.authorizedKeys.keys = [
      # Enzime
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKZfejb9htpSB5K9p0RuEowErkba2BMKaze93ZVkQIE"
    ];
  };

  users.users.luishebendanz = {
    uid = 501;
    shell = pkgs.zsh;
  };

  users.users.admin = {
    uid = 502;
    home = "/Users/admin";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      # Enzime
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKZfejb9htpSB5K9p0RuEowErkba2BMKaze93ZVkQIE"

      # Mic92
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKbBp2dH2X3dcU1zh+xW3ZsdYROKpJd3n13ssOP092qE"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCsjXKHCkpQT4LhWIdT0vDM/E/3tw/4KHTQcdJhyqPSH0FnwC8mfP2N9oHYFa2isw538kArd5ZMo5DD1ujL5dLk="
    ];
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

  system.build.targetUser = "admin";
  system.build.targetHost = "clan-mac-mini.tailfc885e.ts.net";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
