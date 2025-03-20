{
  options,
  self,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    self.nixosModules.jitsi01
    self.nixosModules.vultr-vc2
  ];
  disabledModules = [
    self.inputs.srvos.nixosModules.mixins-cloud-init
  ];

  boot.loader.grub.enable = lib.mkForce false;

  clan.core.sops.defaultGroups = [ "admins" ];

  # Once `networking.fqdn` is no longer readonly, we can just set `networking.fqdn` directly
  programs.ssh.knownHosts.clan-sshd-self-ed25519.hostNames =
    assert options.networking.fqdn.readOnly;
    [
      "jitsi.clan.lol"
    ];

  clan.core.networking.targetHost = "root@jitsi.clan.lol";

  environment.systemPackages = [
    pkgs.python3 # for sshuttle tunneling
  ];
}
