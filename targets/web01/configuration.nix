{ self, config, ... }:
{
  imports = [
    self.nixosModules.web01
    self.nixosModules.hetzner-ax102
  ];
  networking.hostName = "web01";
  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f9:3080:418b::1";

  clan.networking.targetHost = "root@clan.lol";
  clan-infra.networking.ipv4.address = "65.21.12.51";
  clan-infra.networking.ipv4.gateway = "65.21.12.1";
  clan-infra.networking.ipv6.address =
    config.systemd.network.networks."10-uplink".networkConfig.Address;

  system.stateVersion = "23.05";
}
