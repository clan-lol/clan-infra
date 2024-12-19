{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.clan-infra.networking;
in
{
  options = {
    clan-infra.networking.ipv4.address = lib.mkOption { type = lib.types.str; };

    clan-infra.networking.ipv4.cidr = lib.mkOption {
      type = lib.types.str;
      default = "26";
    };

    clan-infra.networking.ipv4.gateway = lib.mkOption { type = lib.types.str; };

    clan-infra.networking.ipv6.address = lib.mkOption { type = lib.types.str; };

    clan-infra.networking.ipv6.cidr = lib.mkOption {
      type = lib.types.str;
      default = "64";
    };
  };

  config = {
    # Hack so that network is considered up by boot.initrd.network and postCommands gets executed.
    boot.kernelParams = [ "ip=127.0.0.1:::::lo:none" ];
    boot.initrd.systemd.enable = false;

    clan.core.vars.generators.initrd-ssh = {
      files."id_ed25519" = { };
      files."id_ed25519.pub".secret = false;
      runtimeInputs = [
        pkgs.coreutils
        pkgs.openssh
      ];
      script = ''
        ssh-keygen -t ed25519 -N "" -f $out/id_ed25519
      '';
    };

    boot.initrd.network = {
      enable = true;
      ssh = {
        enable = true;
        port = 2222;
        hostKeys = [
          config.clan.core.vars.generators.initrd-ssh.files.id_ed25519.path
        ];
        authorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
      };
      postCommands = ''
        ip addr
        ip link set dev enp6s0 up

        ip addr add ${cfg.ipv4.address}/${cfg.ipv4.cidr} dev enp6s0
        ip route add ${cfg.ipv4.gateway} dev enp6s0
        ip route add default via ${cfg.ipv4.gateway} dev enp6s0

        ip -6 addr add ${cfg.ipv6.address}/${cfg.ipv6.cidr} dev enp6s0
        ip -6 route add default via fe80::1 dev enp6s0
      '';

    };
    boot.initrd.kernelModules = [
      # for debugging installation in vms
      "virtio_pci"
      "virtio_net"
    ];
  };
}
