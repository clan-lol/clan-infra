{ self, ... }:
{
  imports = [
    ./borgbackup.nix
    ./gitea
    ./outline.nix
    ./goaccess.nix
    ./harmonia.nix
    ./homepage.nix
    ./matrix-synapse.nix
    ./remote-builder.nix
    ./jumphost.nix
    ./hypervisor.nix
  ];

  nix.settings.extra-substituters = [ "https://hetzner-cache.numtide.com" ];

  services.cloud-init.xfs.enable = true;
}
