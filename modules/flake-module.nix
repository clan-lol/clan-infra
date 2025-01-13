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

    hetzner-ax162r.imports = [
      inputs.srvos.nixosModules.hardware-hetzner-online-amd
      ./zfs-crypto-raid.nix
      ./initrd-networking.nix
    ];

    hetzner-cpx21.imports = [
      inputs.srvos.nixosModules.hardware-hetzner-cloud
      ./zfs-single-disk.nix
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
      ./matrix-bot.nix
      ./web01
      inputs.nixos-mailserver.nixosModules.mailserver
      ./mailserver.nix
    ];

    jitsi01.imports = [
      self.nixosModules.server
      ./jitsi.nix
      ./dev.nix
    ];
  };

  flake.modules.terranix.base = ./terranix.nix;
}
