{ lib, ... }:
let
  hashDisk = disk: "os-${builtins.substring 0 5 (builtins.hashString "sha256" disk)}";
  os = [
    "/dev/disk/by-id/ata-HDSTOR_-_HSAV25ST250AX_HS23082515A173856"
    "/dev/disk/by-id/ata-HDSTOR_-_HSAV25ST250AX_HS23082515A17385A"
  ];
  vdev1 = [
    "/dev/disk/by-id/ata-ST20000NE000-3G5101_ZVT09C24"
    "/dev/disk/by-id/ata-ST20000NE000-3G5101_ZVT0BV94"
    "/dev/disk/by-id/ata-ST20000NE000-3G5101_ZVT0G6YB"
    "/dev/disk/by-id/ata-ST20000NE000-3G5101_ZVT0HC29"
    "/dev/disk/by-id/ata-ST20000NE000-3G5101_ZVT1D6LS"
    "/dev/disk/by-id/ata-ST20000NE000-3G5101_ZVT1MVDX"
  ];
  vdev2 = [
    "/dev/disk/by-id/ata-ST20000NE000-3G5101_ZVT2D5MZ"
    "/dev/disk/by-id/ata-ST20000NE000-3G5101_ZVT6C0TP"
    "/dev/disk/by-id/ata-ST20000NE000-3G5101_ZVT8LKJK"
    "/dev/disk/by-id/ata-ST20000NE000-3G5101_ZVT8ML92"
    "/dev/disk/by-id/ata-WDC_WD201KFGX-68BKJN0_2LG5EBDK"
    "/dev/disk/by-id/ata-WDC_WD201KFGX-68BKJN0_2LG7KE5K"
  ];
  vdev3 = [
    "/dev/disk/by-id/ata-WDC_WD201KFGX-68BKJN0_2LG8LEXK"
    "/dev/disk/by-id/ata-WDC_WD201KFGX-68BKJN0_2LG9U7JK"
    "/dev/disk/by-id/ata-WDC_WD201KFGX-68BKJN0_2LGBP47K"
    "/dev/disk/by-id/ata-WDC_WD201KFGX-68BKJN0_2LGD7M5N"
    "/dev/disk/by-id/ata-WDC_WD201KFGX-68BKJN0_2LGG06AF"
    "/dev/disk/by-id/ata-WDC_WD201KFGX-68BKJN0_8LGNBZKN"
  ];
in
# TODO do something with those
# spares = [
#   "/dev/disk/by-id/ata-WDC_WD201KFGX-68BKJN0_8LGNEXMK"
# ];
{
  disko.devices = {
    disk =
      (lib.listToAttrs (
        map (disk: {
          name = "os-${hashDisk disk}";
          value = {
            type = "disk";
            device = disk;
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
                    mountOptions = [ "nofail" ];
                  };
                };
                system = {
                  size = "100%";
                  content = {
                    type = "zfs";
                    pool = "zroot";
                  };
                };
              };
            };
          };
        }) os
      ))
      // (lib.listToAttrs (
        map (disk: {
          name = "data-${hashDisk disk}";
          value = {
            type = "disk";
            device = disk;
            content = {
              type = "zfs";
              pool = "zdata";
            };
          };
        }) (vdev1 ++ vdev2 ++ vdev3)
      ));
    zpool = {
      zroot = {
        type = "zpool";
        rootFsOptions = {
          mountpoint = "none";
          compression = "lz4";
          acltype = "posixacl";
          xattr = "sa";
          "com.sun:auto-snapshot" = "true";
        };
        options.ashift = "12";
        datasets = {
          "root" = {
            type = "zfs_fs";
            options.mountpoint = "none";
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
          "root/tmp" = {
            type = "zfs_fs";
            mountpoint = "/tmp";
            options = {
              mountpoint = "/tmp";
              sync = "disabled";
            };
          };
        };
      };
      zdata = {
        type = "zpool";
        options.ashift = "12";
        rootFsOptions = {
          mountpoint = "none";
          compression = "lz4";
          acltype = "posixacl";
          xattr = "sa";
          "com.sun:auto-snapshot" = "true";
        };
        mode = {
          topology = {
            type = "topology";
            vdev = [
              {
                members = vdev1;
              }
              {
                members = vdev2;
              }
              {
                members = vdev3;
              }
            ];
          };
        };
        datasets = {
          "nas" = {
            type = "zfs_fs";
            mountpoint = "/mnt/hdd";
            mountOptions = [ "nofail" ];
          };
        };
      };
    };
  };
}
