{ self, ... }:
{
  imports = [
    self.nixosModules.build-x86-01
    ./disko.nix
  ];
  disabledModules = [
    self.inputs.srvos.nixosModules.mixins-cloud-init
  ];
  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f8:192:3223::2";

  clan.core.sops.defaultGroups = [ "admins" ];

  # connections over ZeroTier can access all ports
  networking.firewall.trustedInterfaces = [ "ztqcw3e3rp" ];

  programs.ssh.knownHosts.clan-sshd-self-ed25519.hostNames = [ "144.76.97.38" ];

  clan.core.networking.targetHost = "root@build-x86-01";

  nixpkgs.hostPlatform = "x86_64-linux";
}
