{
  moduleWithSystem,
  flake-parts-lib,
  self,
  inputs,
  ...
}:
{
  flake.nixosModules = {
    server = {
      imports = [
        inputs.srvos.nixosModules.server
        inputs.srvos.nixosModules.mixins-telegraf

        inputs.clan-core.clanModules.root-password
        inputs.clan-core.clanModules.state-version

        ./admins.nix
        ./dev.nix
        ./signing.nix
        ./nix-daemon.nix
      ];
      # FIXME: switch to VPN later
      networking.firewall.allowedTCPPorts = [ 9273 ];

      # server
      boot.kernel.sysctl = {
        "fs.inotify.max_user_instances" = 524288;
        "fs.inotify.max_user_watches" = 524288;
      };
    };

    renovate.imports = [
      inputs.renovate.nixosModules.default
      ./renovate.nix
    ];

    hetzner-amd.imports = [
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
    ];

    demo01.imports = [
      self.nixosModules.server
    ];

    jitsi01.imports = [
      self.nixosModules.server
      ./jitsi.nix
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

    build-x86-01.imports = [
      inputs.srvos.nixosModules.mixins-nix-experimental
      self.nixosModules.hetzner-amd
      self.nixosModules.server
    ];

    web02.imports = [
      inputs.srvos.nixosModules.mixins-nginx

      self.nixosModules.server

      ./web02/kanidm.nix
      ./web02/outline.nix
    ];

    storinator.imports = [
      self.nixosModules.server
    ];
  };

  flake.darwinModules = {
    sshd = ./darwin/sshd.nix;

    server.imports = [
      inputs.srvos.darwinModules.server

      ./admins.nix
      ./dev.nix
      ./signing.nix
    ];

    build02.imports = [
      self.darwinModules.sshd
      self.darwinModules.server

      inputs.srvos.darwinModules.server
      inputs.srvos.darwinModules.mixins-nix-experimental
    ];
  };

  flake.modules.terranix.base = ./terranix/base.nix;
  # use `moduleWithSystem` to give us access to `perSystem`'s `config`
  flake.modules.terranix.with-dns = moduleWithSystem (
    { config }: flake-parts-lib.importApply ./terranix/with-dns.nix { config' = config; }
  );
  flake.modules.terranix.dns = flake-parts-lib.importApply ./terranix/dns.nix { inherit self; };
  flake.modules.terranix.vultr = ./terranix/vultr.nix;
}
