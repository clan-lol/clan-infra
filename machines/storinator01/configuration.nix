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
}
