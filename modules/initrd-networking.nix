{ config, pkgs, ... }:
{
  boot.initrd.systemd.enable = false;

  clan.core.vars.generators.initrd-ssh = {
    files."id_ed25519" = { };
    files."id_ed25519.pub".secret = false;
    runtimeInputs = [
      pkgs.coreutils
      pkgs.openssh
    ];
    script = ''
      ssh-keygen -t ed25519 -N "" -f $out/id_ed25519
    '';
  };

  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 2222;
      hostKeys = [
        config.clan.core.vars.generators.initrd-ssh.files.id_ed25519.path
      ];
      authorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
    };
  };
  boot.initrd.kernelModules = [
    # for debugging installation in vms
    "virtio_pci"
    "virtio_net"
  ];
}
