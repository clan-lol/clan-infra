{
  self,
  lib,
  ...
}:
{
  imports = [
    self.nixosModules.web02
    self.nixosModules.vultr-vc2
  ];
  disabledModules = [
    self.inputs.srvos.nixosModules.mixins-cloud-init
  ];

  boot.loader.grub.enable = lib.mkForce false;

  networking.fqdn = "thecomputer.co";
}
