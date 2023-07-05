{
  imports = [
    ./homepage.nix
    ./gitea.nix
  ];

  services.cloud-init.xfs.enable = true;
}
