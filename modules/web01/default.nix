{
  imports = [
    ./borgbackup.nix
    ./clan-merge.nix
    ./dendrite.nix
    ./gitea
    ./harmonia.nix
    ./homepage.nix
    ./postfix.nix
    ./jobs.nix
    ../zerotier
    ../zerotier/ctrl.nix
  ];

  services.cloud-init.xfs.enable = true;
  clan.sops.sopsDirectory = ../../sops;
}
