{ config, self, pkgs, lib, ... }:

{
  systemd.services.gitea-runner-nix-token = {
    wantedBy = [ "multi-user.target" ];
    after = [ "gitea.service" ];
    environment = {
      GITEA_CUSTOM = "/var/lib/gitea/custom";
      GITEA_WORK_DIR = "/var/lib/gitea";
    };
    script = ''
      set -euo pipefail
      token=$(${lib.getExe self.packages.${pkgs.hostPlatform.system}.gitea} actions generate-runner-token)
      echo "TOKEN=$token" > /var/lib/gitea-actions-runner/token
    '';
    unitConfig.ConditionPathExists = [ "!/var/lib/gitea-actions-runner/token" ];
    serviceConfig = {
      User = "gitea";
      Group = "gitea";
      StateDirectory = "gitea-actions-runner";
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  systemd.services.gitea-runner-nix = {
    after = [ "gitea-runner-nix-token.service" ];
    requires = [ "gitea-runner-nix-token.service" ];
    # TODO: systemd confinment
    #serviceConfig = {
    #  Environment = [
    #    "NIX_REMOTE=daemon"
    #    "PAGER=cat"
    #  ];
    #  BindPaths = [
    #    "/nix/var/nix/daemon-socket/socket"
    #    "/run/nscd/socket"
    #    "/var/lib/drone"
    #  ];
    #};
  };

  services.gitea-actions-runner.instances.nix = {
    enable = true;
    name = "nix-runner";
    # take the git root url from the gitea config
    # only possible if you've also configured your gitea though the same nix config
    # otherwise you need to set it manually
    url = config.services.gitea.settings.server.ROOT_URL;
    # use your favourite nix secret manager to get a path for this
    tokenFile = "/var/lib/gitea-actions-runner/token";
    labels = [ "nix:host" ];
    hostPackages = with pkgs; [
      bash
      coreutils
      curl
      gawk
      gitMinimal
      gnused
      jq
      nixUnstable
      nodejs
      wget
      gnutar
      bash
      config.nix.package
      gzip
    ];
    settings = {
      runner.envs = {
        HOME = "/var/lib/gitea-runner/nix";
      };
    };
  };
}
