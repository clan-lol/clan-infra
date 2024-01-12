{ self, ... }: {
  imports = [
    ./borgbackup.nix
    ./clan-merge.nix
    ./dendrite.nix
    ./gitea
    ./harmonia.nix
    ./homepage.nix
    ./postfix.nix
    ./jobs.nix
    ../dev.nix
    self.inputs.clan-core.clanModules.zt-tcp-relay
  ];

  services.cloud-init.xfs.enable = true;
}
