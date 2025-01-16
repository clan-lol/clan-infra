{ self, ... }:
{
  imports = [
    self.nixosModules.web01
    self.nixosModules.hetzner-ax162r
  ];
  networking.hostName = "web01";
  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f8:2220:1565::1/64";

  clan.core.sops.defaultGroups = [ "admins" ];

  clan.core.networking.targetHost = "root@23.88.17.207";

  system.stateVersion = "23.05";
}
