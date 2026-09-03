{ config, pkgs, ... }:
{
  # These VMs come up on SeaBIOS, not UEFI, so the ESP is never consulted and
  # GRUB has to be embedded in the EF02 partition below. The ESP is kept as a
  # FAT /boot so this can be flipped back to systemd-boot without
  # repartitioning should the VM ever be moved to UEFI firmware.
  boot.loader.grub.enable = true;

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

  boot.zfs.forceImportRoot = false;

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

  boot.zfs.devNodes = "/dev/disk/by-path";

  disko.devices = {
    disk = {
      primary = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            # Embeds GRUB's core.img; disko orders EF02 first and points
            # boot.loader.grub.devices at this disk automatically.
            bios = {
              size = "1M";
              type = "EF02";
            };
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

          # Compaction rewrites these constantly, so the pool's inherited
          # auto-snapshot would pin every block retention deletes.
          "root/mimir" = {
            type = "zfs_fs";
            options = {
              mountpoint = "/var/lib/mimir";
              compression = "zstd";
              "com.sun:auto-snapshot" = "false";
            };
            mountpoint = "/var/lib/mimir";
          };
          "root/loki" = {
            type = "zfs_fs";
            options = {
              mountpoint = "/var/lib/loki";
              compression = "zstd";
              "com.sun:auto-snapshot" = "false";
            };
            mountpoint = "/var/lib/loki";
          };
        };
      };
    };
  };
}
