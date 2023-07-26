{
  imports = [
    ./borgbackup.nix
    ./clan-merge.nix
    ./dendrite.nix
    ./gitea
    ./harmonia.nix
    ./homepage.nix
    ./postfix.nix
    ./job-flake-update.nix
    ../zerotier
    ../zerotier/ctrl.nix
  ];

  services.cloud-init.xfs.enable = true;
}
