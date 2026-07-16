{
  moduleWithSystem,
  flake-parts-lib,
  self,
  inputs,
  ...
}:
{
  flake.nixosModules = {
    server =
      { lib, ... }:
      {
        imports = [
          inputs.srvos.nixosModules.server
          inputs.srvos.nixosModules.mixins-telegraf
          inputs.srvos.nixosModules.mixins-nix-experimental

          ./admins.nix
          ./dev.nix
          ./nix-daemon.nix
          ./shared.nix
          ./signing.nix
          ./variants.nix
        ];

        clan.core.settings.state-version.enable = true;

        # FIXME: switch to VPN later
        networking.firewall.allowedTCPPorts = [ 9273 ];

        # server
        boot.kernel.sysctl = {
          "fs.inotify.max_user_instances" = 524288;
          "fs.inotify.max_user_watches" = 524288;
        };

        # Override the mkForce inside SrvOS as it breaks ssh-copy-id and nixos-anywhere
        services.openssh.authorizedKeysFiles = lib.mkOverride 49 [
          "%h/.ssh/authorized_keys"
          "/etc/ssh/authorized_keys.d/%u"
        ];
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

    nixbot.imports = [
      inputs.nixbot.nixosModules.nixbot
      ./nixbot.nix
    ];

    build01.imports = [
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
      inputs.gitea-mq.nixosModules.default

      self.nixosModules.server
      self.nixosModules.nixbot

      ./web01
      ./mailserver.nix
      ./vaultwarden.nix
    ];

    web02.imports = [
      inputs.srvos.nixosModules.mixins-nginx

      self.nixosModules.server

      ./web02/kanidm.nix
      ./web02/matrix-synapse.nix
      ./web02/outline.nix
      ./web02/personal-computing.nix
    ];

    storinator.imports = [
      self.nixosModules.server
    ];
  };

  flake.darwinModules = {
    base = ./darwin/base.nix;
    sshd = ./darwin/sshd.nix;

    server.imports = [
      inputs.srvos.darwinModules.server
      inputs.srvos.darwinModules.mixins-nix-experimental

      self.darwinModules.base

      ./admins.nix
      ./dev.nix
      ./nix-daemon.nix
      ./shared.nix
      ./signing.nix
    ];

    build02.imports = [
      self.darwinModules.sshd
      self.darwinModules.server
    ];

    build04.imports = [
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
  flake.modules.terranix.build04 = ../machines/build04/terraform-configuration.nix;
  flake.modules.terranix.build-x86-01 = ../machines/build-x86-01/terraform-configuration.nix;
  flake.modules.terranix.jitsi01 = ../machines/jitsi01/terraform-configuration.nix;
  flake.modules.terranix.storinator01 =
    flake-parts-lib.importApply ../machines/storinator01/terraform-configuration.nix
      {
        inherit self;
      };
  flake.modules.terranix.web01 = ../machines/web01/terraform-configuration.nix;
  flake.modules.terranix.web02 = ../machines/web02/terraform-configuration.nix;
}
