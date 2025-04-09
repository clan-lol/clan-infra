{
  config,
  self,
  lib,
  ...
}:
{
  services.tailscale.enable = true;

  nix.distributedBuilds = true;

  nix.buildMachines = [
    {
      hostName = "build02";
      sshUser = "buildbot";
      protocol = "ssh-ng";
      sshKey = config.clan.core.vars.generators.openssh.files."ssh.id_ed25519".path;
      systems = [ "aarch64-darwin" ];
      maxJobs = 10;
      supportedFeatures = [
        "big-parallel"
        "recursive-nix"
      ];
    }
    {
      hostName = "fda9:b487:2919:3547:3699:9336:90ec:cb59";
      sshUser = "builder";
      protocol = "ssh-ng";
      sshKey = config.clan.core.vars.generators.openssh.files."ssh.id_ed25519".path;
      systems = [ "aarch64-linux" ];
      maxJobs = 80;
      supportedFeatures = [
        "big-parallel"
        "kvm"
        "nixos-test"
        "uid-range"
        "recursive-nix"
      ];
    }
  ];

  nix.settings.trusted-public-keys = [
    self.nixosConfigurations.build01.config.clan.core.vars.generators.nix-signing-key.files."key.pub".value
  ];

  # Use `vars` once it has nix-darwin support
  programs.ssh.knownHosts.build02.publicKey =
    assert !lib.hasAttrByPath [ "clan" "core" "vars" ] self.darwinConfigurations.build02.config;
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBHLndcrM45W12GD8w9O/0DKzTYyGWUSr6O+77nla5bj";
}
