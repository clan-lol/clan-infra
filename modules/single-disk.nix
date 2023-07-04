{ self, ... }:
let
  partitions = {
    grub = {
      name = "grub";
      size = "1M";
      flags = [ "bios_grub" ];
    };
    esp = {
      name = "ESP";
      size = "500MB";
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
      };
    };
    root = {
      name = "root";
      size = "100%";
      bootable = true;
      content = {
        type = "filesystem";
        # We use xfs because it has support for compression and has a quite good performance for databases
        format = "xfs";
        mountpoint = "/";
      };
    };
  };
in
{
  imports = [
    self.inputs.disko.nixosModules.disko
  ];
  disko.devices = {
    disk.sda = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        inherit partitions;
      };
    };
  };
}
