{ options, self, ... }:
{
  imports = [
    self.nixosModules.web01
    self.nixosModules.hetzner-ax162r
  ];
  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f8:2220:1565::1/64";

  clan.core.sops.defaultGroups = [ "admins" ];

  # Once `networking.fqdn` is no longer readonly, we can just set `networking.fqdn` directly
  programs.ssh.knownHosts.clan-sshd-self-ed25519.hostNames =
    assert options.networking.fqdn.readOnly;
    [
      "clan.lol"
    ];

  clan.core.networking.targetHost = "root@clan.lol";
}
