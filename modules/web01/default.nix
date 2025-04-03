{ self, ... }:
{
  imports = [
    ./borgbackup.nix
    ./gitea
    ./outline.nix
    ./goaccess.nix
    ./harmonia.nix
    ./homepage.nix
    ./matrix-synapse.nix
    ./remote-builder.nix
    ../dev.nix
    ./iperf3.nix
    ./jumphost.nix
    self.inputs.clan-core.clanModules.zt-tcp-relay
  ];

  nix.settings.extra-substituters = [ "https://hetzner-cache.numtide.com" ];

  clan.sshd.hostKeys.rsa.enable = true;
  services.cloud-init.xfs.enable = true;
}
