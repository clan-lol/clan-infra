{ lib, pkgs, ... }:
{
  nix.settings.sandbox = "relaxed";

  services.openssh.enable = true;

  users.users.root = {
    uid = 0;
    # Necessary because nix-darwin doesn't correctly set the PATH
    # for sh or bash so `ssh root@clan-mac-mini nix-daemon --version`
    # will fail with `command not found`
    shell = lib.mkForce pkgs.zsh;
  };

  # don't let users in the admin group be trusted users
  nix.settings.trusted-users = [
    "root"
  ];

  users.knownUsers = [ "root" ];
}
