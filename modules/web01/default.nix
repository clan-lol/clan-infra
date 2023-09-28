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
    ../dev.nix
  ];

  services.cloud-init.xfs.enable = true;
}
