{ config, ... }:
{
  services.tailscale.enable = true;

  nix.distributedBuilds = true;

  nix.buildMachines = [
    {
      hostName = "clan-mac-mini.tailfc885e.ts.net";
      sshUser = "buildbot";
      protocol = "ssh-ng";
      sshKey = config.clan.core.vars.generators.openssh.files."ssh.id_ed25519".path;
      systems = [ "aarch64-darwin" ];
      maxJobs = 10;
      supportedFeatures = [ "big-parallel" ];
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
      ];
    }
  ];
}
