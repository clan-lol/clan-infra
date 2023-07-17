{ self, config, ... }:
let
  admins = builtins.fromJSON (builtins.readFile ../admins/users.json);
in
{
  imports = [
    self.nixosModules.web01
    self.nixosModules.hetzner-ex101
  ];
  networking.hostName = "web01";
  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f9:3080:282a::1";
  sops.defaultSopsFile = ./secrets.yaml;
  users.users.root.openssh.authorizedKeys.keys = builtins.attrValues admins;

  clan.networking.ipv4.address = "65.109.103.5";
  clan.networking.ipv4.gateway = "65.109.103.1";
  clan.networking.ipv6.address = config.systemd.network.networks."10-uplink".networkConfig.Address;

  system.stateVersion = "23.05";
}
