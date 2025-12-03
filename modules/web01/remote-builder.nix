{
  config,
  self,
  ...
}:
{
  services.tailscale.enable = true;

  nix.distributedBuilds = true;

  nix.buildMachines = [
    {
      hostName = "build-x86-01.clan.lol";
      sshUser = "builder";
      protocol = "ssh-ng";
      sshKey = config.clan.core.vars.generators.openssh.files."ssh.id_ed25519".path;
      system = "x86_64-linux";
      maxJobs = 32;
      supportedFeatures = [
        "big-parallel"
        "kvm"
        "nixos-test"
        "uid-range"
        "recursive-nix"
      ];
    }
    {
      hostName = "build02.vpn.clan.lol";
      sshUser = "builder";
      protocol = "ssh-ng";
      sshKey = config.clan.core.vars.generators.openssh.files."ssh.id_ed25519".path;
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      maxJobs = 10;
      supportedFeatures = [
        "big-parallel"
        "recursive-nix"
      ];
    }
    {
      hostName = "build01.clan.lol";
      sshUser = "builder";
      protocol = "ssh-ng";
      sshKey = config.clan.core.vars.generators.openssh.files."ssh.id_ed25519".path;
      system = "aarch64-linux";
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

  programs.ssh.knownHosts."build02.vpn.clan.lol".publicKey =
    self.darwinConfigurations.build02.config.clan.core.vars.generators.openssh.files."ssh.id_ed25519.pub".value;
}
