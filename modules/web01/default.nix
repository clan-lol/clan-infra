{
  imports = [
    ./homepage.nix
    ./gitea
    ./postfix.nix
    ./harmonia.nix
    ../zerotier
    ../zerotier/ctrl.nix
  ];

  services.cloud-init.xfs.enable = true;
}
