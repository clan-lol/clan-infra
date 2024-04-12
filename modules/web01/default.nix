{ self, ... }: {
  imports = [
    ./borgbackup.nix
    ./clan-merge.nix
    ./gitea
    ./harmonia.nix
    ./homepage.nix
    ./postfix.nix
    ./jobs.nix
    #./matrix-synapse.nix
    ../dev.nix
    self.inputs.clan-core.clanModules.zt-tcp-relay
  ];

  services.cloud-init.xfs.enable = true;
}
