{ self, inputs, ... }:
{
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

    buildbot.imports = [
      inputs.buildbot-nix.nixosModules.buildbot-master
      inputs.buildbot-nix.nixosModules.buildbot-worker
      ./buildbot.nix
    ];

    web01.imports = [
      self.nixosModules.server
      self.nixosModules.buildbot
      inputs.srvos.nixosModules.mixins-nginx
      inputs.srvos.nixosModules.mixins-nix-experimental
      ./web01
      inputs.nixos-mailserver.nixosModules.mailserver
      ./mailserver.nix
    ];
  };
}
