{ config, pkgs, ... }:
{
  networking.hostId = "87fa8a2a";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
      primary = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
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
    };
    zpool = {
      zroot = {
        type = "zpool";
        rootFsOptions = {
          compression = "lz4";
          "com.sun:auto-snapshot" = "true";
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
        };
      };
    };
  };
}
