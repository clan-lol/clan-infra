{
  imports = [
    ./borgbackup.nix
    ./gitea
    ./goaccess.nix
    ./homepage.nix
    ./hypervisor.nix
    ./jumphost.nix
    ./matrix-synapse.nix
    ./nextcloud.nix
    ./niks3.nix
    ./outline.nix
    ./remote-builder.nix
  ];

  nix.settings.extra-substituters = [ "https://hetzner-cache.numtide.com" ];

  services.cloud-init.xfs.enable = true;
}
