{
  config,
  self,
  pkgs,
  ...
}:
{
  imports = [
    self.darwinModules.build04
  ];

  users.users.customer = {
    uid = 501;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
  };

  users.knownUsers = [
    "customer"
  ];

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
