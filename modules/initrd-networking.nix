{ config
, lib
, ...
}:
with lib; let
  cfg = config.clan.networking;
in
{
  options = {
    clan.networking.ipv4.address = mkOption {
      type = types.str;
    };

    clan.networking.ipv4.cidr = mkOption {
      type = types.str;
      default = "26";
    };

    clan.networking.ipv4.gateway = mkOption {
      type = types.str;
    };

    clan.networking.ipv6.address = mkOption {
      type = types.str;
    };

    clan.networking.ipv6.cidr = mkOption {
      type = types.str;
      default = "64";
    };
  };

  config = {
    # Hack so that network is considered up by boot.initrd.network and postCommands gets executed.
    boot.kernelParams = [ "ip=127.0.0.1:::::lo:none" ];
    boot.initrd.systemd.enable = false;

    boot.initrd.network = {
      enable = true;
      ssh = {
        enable = true;
        port = 2222;
        hostKeys = [
          # not using sops here because we cannot reliable deploy this secret
          #config.sops.secrets.initrd-ssh-key.path
          "/var/lib/secrets/initrd_ssh_key"
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
      "e1000e" # older hetzner machines, 1 GbE nics
      "igc" # newer herzner machines, 2.5 GbE nics
      "igb"
      # for debugging installation in vms
      "virtio_pci"
      "virtio_net"
    ];
  };
}
