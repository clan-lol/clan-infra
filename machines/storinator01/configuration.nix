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

  clan.core.networking.targetHost = "root@10.0.200.124";
}
