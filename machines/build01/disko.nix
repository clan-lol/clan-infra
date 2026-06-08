{
  config,
  lib,
  pkgs,
  ...
}:
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
            mountOptions = [
              "umask=0077"
              "nofail"
            ];
          };
        };
        swap = {
          size = "16G";
          content = {
            type = "swap";
            discardPolicy = "both";
            randomEncryption = true;
            # equal priority on both disks ⇒ kernel stripes writes across them after filling zram
            priority = config.zramSwap.priority - 1;
          };
        };
        mdraid = {
          size = "100%";
          content = {
            type = "mdraid";
            name = "stripe";
          };
        };
      };
    };
  };
in
{
  services.fstrim.enable = true;

  # Disable monitoring on this server as it's just a build server
  boot.swraid.mdadmConf = "MAILADDR root";
  systemd.services.mdmonitor.enable = false;

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

  clan.core.vars.generators.luks = {
    files.password.neededFor = "partitioning";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.xkcdpass
    ];
    script = ''
      xkcdpass --numwords 6 --random-delimiters --valid-delimiters='1234567890!@#$%^&*()-_+=,.<>/?' --case random | tr -d "\n" > $out/password
    '';
  };

  disko.devices = {
    disk = {
      x = mirrorBoot "0";
      y = mirrorBoot "1";
    };
    mdadm.stripe = {
      type = "mdadm";
      level = 0;
      content = {
        type = "luks";
        name = "cryptroot";
        passwordFile = config.clan.core.vars.generators.luks.files.password.path;
        settings = {
          allowDiscards = true;
          bypassWorkqueues = true;
        };
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/";
          mountOptions = [ "noatime" ];
          extraArgs = [
            # Increases maximum number of files per directory
            "-O"
            "large_dir"
            # more efficient lookups in large directories
            "-O"
            "dir_index"
            # shrink root-reserved blocks from the 5% default
            "-m"
            "1"
          ];
        };
      };
    };
  };

  virtualisation.vmVariantWithDisko = {
    boot.loader.grub.devices = lib.mkForce [ ];
    disko.devices.mdadm.stripe.content.passwordFile = lib.mkForce (
      toString (pkgs.writeText "password" "apple")
    );
  };
}
