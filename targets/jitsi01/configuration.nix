{ self, ... }:
{
  imports = [
    self.nixosModules.jitsi01
    self.nixosModules.hetzner-cpx21
  ];
  networking.hostName = "jitsi01";
  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4ff:1f0:9308::1/64";

  clan.core.sops.defaultGroups = [ "admins" ];

  clan.core.networking.targetHost = "root@jitsi.clan.lol";

  system.stateVersion = "25.05";
}
