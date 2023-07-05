{
  imports = [
    ./homepage.nix
    ./gitea
    ./postfix.nix
  ];

  services.cloud-init.xfs.enable = true;
}
