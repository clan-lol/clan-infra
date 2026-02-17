{
  self,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    self.nixosModules.jitsi01
    self.nixosModules.vultr-vc2
  ];
  disabledModules = [
    self.inputs.srvos.nixosModules.mixins-cloud-init
  ];

  boot.loader.grub.enable = lib.mkForce false;

  networking.fqdn = "jitsi.clan.lol";

  environment.systemPackages = [
    pkgs.python3 # for sshuttle tunneling
  ];
}
