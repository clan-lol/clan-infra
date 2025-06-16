{ self, ... }:
{
  imports = [
    self.nixosModules.storinator
    ./disko.nix
    ./users.nix
    ./incus.nix
    ../../modules/samba.nix
    ../../modules/ollama.nix
  ];

  systemd.services."serial-getty@ttyS0".enable = true;

  disabledModules = [
    self.inputs.srvos.nixosModules.mixins-cloud-init
  ];

  clan.core.sops.defaultGroups = [ "admins" ];

  programs.ssh.knownHosts.clan-sshd-self-ed25519.hostNames = [
    "fda9:b487:2919:3547:3699:9393:7f57:6e6b"
  ];

  clan.core.networking.targetHost = "root@storinator01";
}
