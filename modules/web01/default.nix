{
  imports = [
    ./borgbackup.nix
    ./gitea
    ./gitea-mq.nix
    ./heisenbridge.nix
    ./homepage.nix
    ./jumphost.nix
    ./matrix-synapse.nix
    ./nextcloud.nix
    ./niks3.nix
    ./outline.nix
    ./remote-builder.nix
  ];

  services.journald.extraConfig = ''
    SystemMaxUse=64G
    SystemMaxFiles=1000
  '';

  nix.settings.extra-substituters = [ "https://hetzner-cache.numtide.com" ];

  services.cloud-init.xfs.enable = true;
}
