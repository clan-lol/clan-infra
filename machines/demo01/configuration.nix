{ self, lib, ... }:
{
  imports = [
    self.nixosModules.demo01
    self.nixosModules.vultr-vc2
  ];
  disabledModules = [
    self.inputs.srvos.nixosModules.mixins-cloud-init
  ];

  boot.loader.grub.enable = lib.mkForce false;

  clan.core.sops.defaultGroups = [ "admins" ];

  clan.core.networking.targetHost = "root@45.77.34.53";
}
