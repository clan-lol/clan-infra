{
  imports = [
    ./homepage.nix
    ./gitea.nix
    ./postfix.nix
  ];

  services.cloud-init.xfs.enable = true;
}
