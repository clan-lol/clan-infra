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
        inputs.srvos.nixosModules.mixins-nix-experimental

        ./admins.nix
        ./dev.nix
        ./nix-daemon.nix
        ./signing.nix
      ];
      clan.core.settings.state-version.enable = true;

      # FIXME: switch to VPN later
      networking.firewall.allowedTCPPorts = [ 9273 ];

      # server
      boot.kernel.sysctl = {
        "fs.inotify.max_user_instances" = 524288;
        "fs.inotify.max_user_watches" = 524288;
      };

      nix.gc.automatic = true;
      nix.gc.dates = [ "weekly" ];
    };

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
    ];

    demo01.imports = [
      self.nixosModules.server
    ];

    jitsi01.imports = [
      self.nixosModules.server
      ./jitsi.nix
      ./lasuite-meet.nix
    ];

    web01.imports = [
      inputs.srvos.nixosModules.mixins-nginx

      inputs.nixos-mailserver.nixosModules.mailserver
      inputs.niks3.nixosModules.niks3

      self.nixosModules.server
      self.nixosModules.buildbot

      ./web01
      ./mailserver.nix
      ./vaultwarden.nix
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
      inputs.srvos.darwinModules.mixins-nix-experimental

      ./admins.nix
      ./dev.nix
      ./nix-daemon.nix
      ./signing.nix
    ];

    build02.imports = [
      self.darwinModules.sshd
      self.darwinModules.server
    ];
  };

  flake.modules.terranix.base = ./terranix/base.nix;
  # use `moduleWithSystem` to give us access to `perSystem`'s `config`
  flake.modules.terranix.with-dns = moduleWithSystem (
    { config }: flake-parts-lib.importApply ./terranix/with-dns.nix { config' = config; }
  );
  flake.modules.terranix.dns = ./terranix/dns.nix;
  flake.modules.terranix.vultr = ./terranix/vultr.nix;
  flake.modules.terranix.cache = ./terranix/cache.nix;
  flake.modules.terranix.cache-new = ./terranix/cache-new.nix;

  flake.modules.terranix.build01 =
    flake-parts-lib.importApply ../machines/build01/terraform-configuration.nix
      {
        inherit self;
      };
  flake.modules.terranix.build02 = ../machines/build02/terraform-configuration.nix;
  flake.modules.terranix.build-x86-01 = ../machines/build-x86-01/terraform-configuration.nix;
  flake.modules.terranix.demo01 = ../machines/demo01/terraform-configuration.nix;
  flake.modules.terranix.jitsi01 = ../machines/jitsi01/terraform-configuration.nix;
  flake.modules.terranix.storinator01 =
    flake-parts-lib.importApply ../machines/storinator01/terraform-configuration.nix
      {
        inherit self;
      };
  flake.modules.terranix.web01 = ../machines/web01/terraform-configuration.nix;
  flake.modules.terranix.web02 = ../machines/web02/terraform-configuration.nix;
}
