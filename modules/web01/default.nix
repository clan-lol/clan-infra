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

  # Busiest machine we run, so keep more than the shared 32G ceiling.
  services.journald.settings.Journal.SystemMaxUse = "64G";

  nix.settings.extra-substituters = [ "https://hetzner-cache.numtide.com" ];

  services.cloud-init.xfs.enable = true;
}
