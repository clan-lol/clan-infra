{ pkgs, ... }: {
  # Enable raid support specifically, this will disable srvos's
  # systemd-initrd as well, which currently is not compatible with mdraid.
  boot.initrd.services.swraid.enable = true;
  systemd.services.mdmonitor.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # We are not limited by zfs, so we can use the latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  powerManagement.cpuFreqGovernor = "powersave";
}
