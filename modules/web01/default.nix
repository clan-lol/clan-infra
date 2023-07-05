{
  imports = [
    ./homepage.nix
    ./gitea
    ./postfix.nix
    ../zerotier
    ../zerotier/ctrl.nix
  ];

  services.cloud-init.xfs.enable = true;
}
