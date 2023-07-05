{
  imports = [
    ./homepage.nix
    ./gitea
    ./postfix.nix
    ./zerotier.nix
    ./zerotier-ctrl.nix
  ];

  services.cloud-init.xfs.enable = true;
}
