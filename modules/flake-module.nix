{
  flake-parts-lib,
  self,
  inputs,
  ...
}:
{
  flake.nixosModules = {
    server.imports = [
      inputs.srvos.nixosModules.server
      inputs.srvos.nixosModules.mixins-telegraf

      inputs.clan-core.clanModules.root-password
      inputs.clan-core.clanModules.state-version

      # FIXME: switch to VPN later
      { networking.firewall.allowedTCPPorts = [ 9273 ]; }

      ./emergency-access.nix
      ./admins.nix
      ./signing.nix
      ./nix-daemon.nix
    ];

    renovate.imports = [
      inputs.renovate.nixosModules.default
      ./renovate.nix
    ];

    hetzner-ax162r.imports = [
      inputs.srvos.nixosModules.hardware-hetzner-online-amd
      ./initrd-networking.nix
    ];

    hetzner-rx170.imports = [
      inputs.srvos.nixosModules.hardware-hetzner-online-arm
      ./initrd-networking.nix
    ];

    vultr-vc2.imports = [
      inputs.srvos.nixosModules.hardware-vultr-vm
      ./initrd-networking.nix
    ];

    buildbot.imports = [
      inputs.buildbot-nix.nixosModules.buildbot-master
      inputs.buildbot-nix.nixosModules.buildbot-worker
      ./buildbot.nix
    ];

    build01.imports = [
      self.nixosModules.server
      inputs.srvos.nixosModules.mixins-nix-experimental
      ./builder.nix
      ./dev.nix
    ];

    demo01.imports = [
      self.nixosModules.server
      ./dev.nix
    ];

    jitsi01.imports = [
      self.nixosModules.server
      ./jitsi.nix
      ./dev.nix
    ];

    web01.imports = [
      inputs.srvos.nixosModules.mixins-nginx
      inputs.srvos.nixosModules.mixins-nix-experimental

      inputs.nixos-mailserver.nixosModules.mailserver

      self.nixosModules.server
      self.nixosModules.buildbot
      self.nixosModules.renovate

      ./matrix-bot.nix
      ./web01
      ./mailserver.nix
    ];

    storinator.imports = [
      self.nixosModules.server
    ];
  };

  flake.darwinModules = {
    sshd = ./darwin/sshd.nix;

    build02.imports = [
      self.darwinModules.sshd

      inputs.srvos.darwinModules.server
      inputs.srvos.darwinModules.mixins-nix-experimental

      ./admins.nix
    ];
  };

  flake.modules.terranix.base = ./terranix/base.nix;
  flake.modules.terranix.dns = flake-parts-lib.importApply ./terranix/dns.nix { inherit self; };
  flake.modules.terranix.vultr = ./terranix/vultr.nix;
}
