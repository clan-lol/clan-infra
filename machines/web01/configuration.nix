{ self, ... }:
{
  imports = [
    self.nixosModules.web01
    self.nixosModules.hetzner-amd
  ];
  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f8:2220:1565::1/64";

  clan.core.sops.defaultGroups = [ "admins" ];

  networking.fqdn = "clan.lol";

  nix.settings.max-jobs = 0;
  nix.settings.cores = 32;

  # Check https://nixos-mailserver.readthedocs.io/en/latest/migrations.html before bumping
  mailserver.stateVersion = 2;

  # zram for extra memory
  zramSwap.enable = true;
  zramSwap.memoryPercent = 100;
}
