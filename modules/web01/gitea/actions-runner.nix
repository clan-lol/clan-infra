{ config, self, pkgs, lib, ... }:

let
  inherit (self.packages.${pkgs.hostPlatform.system}) actions-runner;
in
{
  systemd.services.gitea-actions-runner-nix-image = {
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${lib.getExe pkgs.podman} load --input=${actions-runner}
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
  systemd.services.gitea-actions-runner-nix-token = {
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
    serviceConfig = {
      User = "gitea";
      Group = "gitea";
      StateDirectory = "gitea-actions-runner";
      ConditionPathExists = [ "!/var/lib/gitea-actions-runner/token" ];
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # Format of the token file:
  virtualisation.podman.enable = true;

  systemd.services.gitea-runner-nix = {
    after = [
      "gitea-actions-runner-nix-token.service"
      "gitea-actions-runner-nix-image.service"
    ];
    requires = [
      "gitea-actions-runner-nix-token.service"
      "gitea-actions-runner-nix-image.service"
    ];
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
    labels = [
      "nix:docker://${actions-runner.imageName}"
    ];
  };
}
