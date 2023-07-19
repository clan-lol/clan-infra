{ pkgs, ... }: {
  # Enable raid support specifically, this will disable srvos's
  # systemd-initrd as well, which currently is not compatible with mdraid.
  boot.initrd.services.swraid.enable = true;
  systemd.services.mdmonitor.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # We are not limited by zfs, so we can use the latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # looks like the Intel i9-13900 draws too much power and crashes the system
  systemd.services.limit-cpu-freq = {
    description = "Limit CPU frequency to 4GHz";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    # Some cores do have a scaling max freq less than 5GHz, so we need to
    # check for that or else all cores will run at 800MHz
    script = ''
      #!/bin/sh
      for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
        old_val="$(<"$f")"
        if [[ "$old_val" -gt 4000000 ]]; then
          echo 4000000 > "$f"
        fi
      done
    '';
    serviceConfig = {
      Type = "oneshot";
    };
  };
}
