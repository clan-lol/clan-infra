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

    web01.imports = [
      self.nixosModules.server
      ./web01
    ];
  };
}
