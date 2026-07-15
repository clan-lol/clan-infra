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
      hostName = "build04.clan.lol";
      sshUser = "builder";
      protocol = "ssh-ng";
      sshKey = config.clan.core.vars.generators.openssh.files."ssh.id_ed25519".path;
      systems = [
        "aarch64-darwin"
      ];
      maxJobs = 10;
      supportedFeatures = [
        "big-parallel"
        "recursive-nix"
      ];
    }
  ];

  programs.ssh.knownHosts = {
    "build01.clan.lol".publicKey =
      self.nixosConfigurations.build01.config.clan.core.vars.generators.openssh.files."ssh.id_ed25519.pub".value;
    "build-x86-01.clan.lol".publicKey =
      self.nixosConfigurations.build-x86-01.config.clan.core.vars.generators.openssh.files."ssh.id_ed25519.pub".value;
    "build02.vpn.clan.lol".publicKey =
      self.darwinConfigurations.build02.config.clan.core.vars.generators.openssh.files."ssh.id_ed25519.pub".value;
    "build04.clan.lol".publicKey =
      self.darwinConfigurations.build04.config.clan.core.vars.generators.openssh.files."ssh.id_ed25519.pub".value;
    # web01 copies storinator01's closure over the tunnel ProxyJump, which loops
    # back through web01 itself, so it must trust both its own key and storinator01.
    "web01.clan.lol".publicKey =
      config.clan.core.vars.generators.openssh.files."ssh.id_ed25519.pub".value;
    "storinator01.wireguard-infra".publicKey =
      self.nixosConfigurations.storinator01.config.clan.core.vars.generators.openssh.files."ssh.id_ed25519.pub".value;
  };

  # The buildHost -> targetHost closure copy runs as root on web01 with an empty
  # /root/.ssh, so point it at web01's clan-managed host key for authentication.
  programs.ssh.extraConfig = ''
    Host storinator01.wireguard-infra web01.clan.lol
      IdentityFile ${config.clan.core.vars.generators.openssh.files."ssh.id_ed25519".path}
      IdentitiesOnly yes
  '';
}
