{ self, lib, ... }:

let
  disk = index: {
    type = "disk";
    device = "/dev/nvme${toString index}n1";
    content = {
      type = "gpt";
      partitions =
        # systemd only wants to have one /boot partition
        # should we rsync?
        (lib.optionalAttrs (index == 0) {
          boot = {
            type = "EF00";
            size = "1G";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
        }) // {
          root = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted${toString index}";
              keyFile = "/tmp/secret.key";
              content = {
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
    };
  };
in
{
  imports = [
    self.inputs.disko.nixosModules.disko
  ];

  boot.initrd.kernelModules = [
    "xhci_pci"
    "ahci"
    "sd_mod"
    "nvme"
    "dm-raid"
    "dm-integrity"
  ];

  disko.devices = {
    disk = {
      nvme0n1 = disk 0;
      nvme1n1 = disk 1;
    };

    lvm_vg = {
      pool = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "95%FREE";
            lvm_type = "raid1";
            extraArgs = [
              "--raidintegrity"
              "y"
            ];
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/";
              mountOptions = [
                "defaults"
              ];
            };
          };
        };
      };
    };
  };
}
