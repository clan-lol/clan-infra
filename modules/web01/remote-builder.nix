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
      hostName = "144.76.97.38";
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
      # Once we are using Nix >= 2.31.2, we can remove the brackets again
      hostName =
        assert lib.versionAtLeast config.nix.package.version "2.31.1";
        "[fda9:b487:2919:3547:3699:9336:90ec:cb59]";
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

  nix.settings.trusted-public-keys = [
    self.nixosConfigurations.build01.config.clan.core.vars.generators.nix-signing-key.files."key.pub".value
  ];

  programs.ssh.knownHosts."build02.vpn.clan.lol".publicKey =
    self.darwinConfigurations.build02.config.clan.core.vars.generators.openssh.files."ssh.id_ed25519.pub".value;
}
