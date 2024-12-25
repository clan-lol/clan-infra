{ self, config, ... }:
{
  imports = [
    ./borgbackup.nix
    ./clan-merge.nix
    ./gitea
    ./goaccess.nix
    ./harmonia.nix
    ./homepage.nix
    ./postfix.nix
    ./jobs.nix
    ./matrix-synapse.nix
    ../dev.nix
    self.inputs.clan-core.clanModules.zt-tcp-relay
  ];

  clan.sshd.hostKeys.rsa.enable = true;
  services.cloud-init.xfs.enable = true;
}
