{ self, inputs, ... }: {
  flake.nixosModules = {
    server.imports = [
      inputs.srvos.nixosModules.server
      inputs.srvos.nixosModules.mixins-telegraf
      # FIXME: switch to VPN later
      { networking.firewall.allowedTCPPorts = [ 9273 ]; }

      ./admins.nix
    ];

    hetzner-ax102.imports = [
      inputs.srvos.nixosModules.hardware-hetzner-online-amd
      ./zfs-crypto-raid.nix
      ./initrd-networking.nix
    ];

    web01.imports = [
      self.nixosModules.server
      inputs.srvos.nixosModules.mixins-nginx
      inputs.srvos.nixosModules.mixins-nix-experimental
      ./web01
    ];
  };
}
