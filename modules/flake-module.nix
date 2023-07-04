{ inputs, ... }: {
  flake.nixosModules = {
    hcloud.imports = [
      inputs.srvos.nixosModules.server
      inputs.srvos.nixosModules.hardware-hetzner-cloud
      ./single-disk.nix
    ];

    web01.imports = [
      inputs.srvos.nixosModules.mixins-nginx
      ./web01
    ];
  };
}
