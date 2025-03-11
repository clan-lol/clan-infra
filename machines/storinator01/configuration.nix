{ self, lib, ... }:
{
  imports = [
    self.nixosModules.storinator
    ./disko.nix
  ];

  systemd.services."serial-getty@ttyS0".enable = true;

  disabledModules = [
    self.inputs.srvos.nixosModules.mixins-cloud-init
  ];

  clan.core.sops.defaultGroups = [ "admins" ];

  clan.core.networking.targetHost = "root@[fda9:b487:2919:3547:3699:9393:7f57:6e6b]";

  users.users = {
    matthew = {
      # https://github.com/MatthewCroughan/
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      uid = 2001;
      openssh.authorizedKeys.keys = [
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOJDRQfb1+7VK5tOe8W40iryfBWYRO6Uf1r2viDjmsJtAAAABHNzaDo= backup-yubikey"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIDgsWq+G/tcr6eUQYT7+sJeBtRmOMabgFiIgIV44XNc6AAAABHNzaDo= main-yubikey"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJMi3TAuwDtIeO4MsORlBZ31HzaV5bji1fFBPcC9/tWuAAAABHNzaDo= nano-yubikey"
      ];
    };
    w = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      uid = 2002;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINpWOqoN29X9v/2NisR2yFaazGLsEvG6oE+VLlOOIrxB w-main"
      ];
    };
  };

}
