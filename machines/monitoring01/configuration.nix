{
  self,
  ...
}:
{
  imports = [
    self.nixosModules.monitoring01
    self.nixosModules.hetzner-cx
  ];
  disabledModules = [
    self.inputs.srvos.nixosModules.mixins-cloud-init
  ];

  networking.fqdn = "monitoring.clan.lol";
}
