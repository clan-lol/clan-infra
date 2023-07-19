{
  imports = [
    ./homepage.nix
    ./gitea
    ./postfix.nix
    ./harmonia.nix
    ./dendrite.nix
    ./borgbackup.nix
    ../zerotier
    ../zerotier/ctrl.nix
  ];

  services.cloud-init.xfs.enable = true;
}
