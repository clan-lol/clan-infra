{ config, ... }:
{
  virtualisation.incus.enable = true;
  virtualisation.incus.ui.enable = true;

  networking.nftables.enable = true;
  networking.firewall.trustedInterfaces = [ "incusbr0" ];

  virtualisation.incus.preseed = {
    networks = [
      {
        config = {
          "ipv4.nat" = "false";
          # 10.0.200.2-99 is unused and usuable for VMs
          "ipv4.dhcp.ranges" = "10.0.200.50-10.0.200.99";
          "ipv4.address" = "10.0.200.2/24";
          "ipv4.dhcp.gateway" = "10.0.200.1";
        };
        name = "incusbr0";
        type = "bridge";
      }
    ];
    profiles = [
      {
        devices = {
          eth0 = {
            name = "eth0";
            network = "incusbr0";
            type = "nic";
          };
          root = {
            path = "/";
            pool = "default";
            size = "35GiB";
            type = "disk";
          };
        };
        name = "default";
      }
    ];
    storage_pools = [
      {
        config.source = "zdata/incus";
        driver = "zfs";
        name = "default";
      }
      {
        config.source = "zroot/incus";
        driver = "zfs";
        name = "nvme";
      }
    ];
  };
  systemd.services.incus = {
    serviceConfig.ExecStartPre = [
      "-${config.boot.zfs.package}/bin/zfs create -o mountpoint=none -o com.sun:auto-snapshot=false zroot/incus"
      "-${config.boot.zfs.package}/bin/zfs create -o mountpoint=none -o com.sun:auto-snapshot=false zdata/incus"
    ];
  };

}
