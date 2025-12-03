{ self, ... }:
{
  imports = [
    self.nixosModules.build01
    self.nixosModules.hetzner-rx170
  ];
  disabledModules = [
    self.inputs.srvos.nixosModules.mixins-cloud-init
  ];
  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f8:2220:140f::1";

  clan.core.sops.defaultGroups = [ "admins" ];

  services.openssh.openFirewall = false;

  # connections over ZeroTier can access all ports
  networking.firewall.trustedInterfaces = [ "ztqcw3e3rp" ];

  programs.ssh.knownHosts.clan-sshd-self-ed25519.hostNames = [ "157.90.137.201" ];
}
