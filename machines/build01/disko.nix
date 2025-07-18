{ config, pkgs, ... }:
let
  mirrorBoot = idx: {
    type = "disk";
    device = "/dev/nvme${idx}n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot${idx}";
          };
        };
        zfs = {
          size = "100%";
          content = {
            type = "zfs";
            pool = "zroot";
          };
        };
      };
    };
  };
in
{
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
      {
        path = "/boot0";
        devices = [ "nodev" ];
      }
      {
        path = "/boot1";
        devices = [ "nodev" ];
      }
    ];
  };

  clan.core.vars.generators.zfs = {
    files.key.neededFor = "partitioning";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.xxd
    ];
    script = ''
      dd if=/dev/urandom bs=32 count=1 | xxd -c32 -p > $out/key
    '';
  };

  boot.initrd.systemd.services.zfs-import-zroot = {
    preStart = ''
      while [ ! -f ${config.clan.core.vars.generators.zfs.files.key.path} ]; do
        sleep 1
      done
    '';
    unitConfig = {
      StartLimitIntervalSec = 0;
    };
    serviceConfig = {
      RestartSec = "1s";
      Restart = "on-failure";
    };
  };

  disko.devices = {
    disk = {
      x = mirrorBoot "0";
      y = mirrorBoot "1";
    };
    zpool = {
      zroot = {
        type = "zpool";
        rootFsOptions = {
          compression = "lz4";
        };
        datasets = {
          "root" = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              encryption = "aes-256-gcm";
              keyformat = "hex";
              keylocation = "file://${config.clan.core.vars.generators.zfs.files.key.path}";
            };
          };
          "root/nixos" = {
            type = "zfs_fs";
            options.mountpoint = "/";
            mountpoint = "/";
          };
          "root/home" = {
            type = "zfs_fs";
            options.mountpoint = "/home";
            mountpoint = "/home";
          };
          "root/podman" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
        };
      };
    };
  };
}
