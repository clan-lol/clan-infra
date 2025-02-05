{ self, lib, ... }:
{
  imports = [
    self.nixosModules.storinator
    ./disko.nix
  ];
  disabledModules = [
    self.inputs.srvos.nixosModules.mixins-cloud-init
  ];

  clan.core.sops.defaultGroups = [ "admins" ];

  clan.core.networking.targetHost = "root@10.0.200.23";
}
