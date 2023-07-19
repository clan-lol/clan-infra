{ self, inputs, ... }: {
  flake.nixosModules = {
    server.imports = [
      inputs.srvos.nixosModules.server
      inputs.sops-nix.nixosModules.default
    ];

    hcloud.imports = [
      inputs.srvos.nixosModules.hardware-hetzner-cloud
      ./single-disk.nix
    ];

    hetzner-ex101.imports = [
      inputs.srvos.nixosModules.hardware-hetzner-online-intel
      ./xfs-lvm-crypto-raid.nix
      ./hetzner-ex101.nix
      ./initrd-networking.nix
    ];

    web01.imports = [
      self.nixosModules.server
      inputs.srvos.nixosModules.mixins-nginx
      ./web01
    ];
  };
}
