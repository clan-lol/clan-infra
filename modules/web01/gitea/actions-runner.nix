{ config, self, pkgs, lib, ... }:
{
  #systemd.services.gitea-runner-nix-image = {
  #  wantedBy = [ "multi-user.target" ];
  #  script = ''
  #    ${lib.getExe pkgs.podman} load --input=${actions-runner}
  #  '';
  #  serviceConfig = {
  #    Type = "oneshot";
  #    RemainAfterExit = true;
  #  };
  #};

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
      echo "TOKEN=$token" > /var/lib/gitea-registration/token
    '';
    unitConfig.ConditionPathExists = [ "!/var/lib/gitea-registration/token" ];
    serviceConfig = {
      User = "gitea";
      Group = "gitea";
      StateDirectory = "gitea-registration";
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # Format of the token file:
  virtualisation.podman.enable = true;

  systemd.services.gitea-runner-nix = {
    after = [
      "gitea-runner-nix-token.service"
    ];
    requires = [
      "gitea-runner-nix-token.service"
    ];

    # TODO: systemd confinment
    serviceConfig = {
      # Hardening (may overlap with DynamicUser=)
      # The following options are only for optimizing output of systemd-analyze
      AmbientCapabilities = "";
      CapabilityBoundingSet = "";
      # ProtectClock= adds DeviceAllow=char-rtc r
      DeviceAllow = "";
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateMounts = true;
      PrivateTmp = true;
      PrivateUsers = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      UMask = "0066";
      ProtectProc = "invisible";
      SystemCallFilter = [
        "~@clock"
        "~@cpu-emulation"
        "~@module"
        "~@mount"
        "~@obsolete"
        "~@raw-io"
        "~@reboot"
        "~@swap"
        # needed by go?
        #"~@resources"
        "~@privileged"
        "~capset"
        "~setdomainname"
        "~sethostname"
      ];
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];

      # Needs network access
      PrivateNetwork = false;
      # Cannot be true due to Node
      MemoryDenyWriteExecute = false;

      # The more restrictive "pid" option makes `nix` commands in CI emit
      # "GC Warning: Couldn't read /proc/stat"
      # You may want to set this to "pid" if not using `nix` commands
      ProcSubset = "all";
      # Coverage programs for compiled code such as `cargo-tarpaulin` disable
      # ASLR (address space layout randomization) which requires the
      # `personality` syscall
      # You may want to set this to `true` if not using coverage tooling on
      # compiled code
      LockPersonality = false;

      # Note that this has some interactions with the User setting; so you may
      # want to consult the systemd docs if using both.
      DynamicUser = true;
      #  Environment = [
      #  ];
      #  BindPaths = [
      #    "/nix/var/nix/daemon-socket/socket"
      #    "/run/nscd/socket"
      #    "/var/lib/drone"
      #  ];
    };
  };

  services.gitea-actions-runner.instances.nix = let
    extraBins = pkgs.runCommand "extra-bins" {} ''
      mkdir -p $out
      ln -s ${pkgs.nodejs}/bin/node $out/node
    '';
  in {
    enable = true;
    name = "nix-runner";
    # take the git root url from the gitea config
    # only possible if you've also configured your gitea though the same nix config
    # otherwise you need to set it manually
    url = config.services.gitea.settings.server.ROOT_URL;
    # use your favourite nix secret manager to get a path for this
    tokenFile = "/var/lib/gitea-registration/token";
    labels = [ "nix:docker://mic92/nix-unstable-static" ];
    settings = {
      container.options = "-v /nix:/nix -v ${extraBins}:/host/bin --user nixuser";
    };
  };
}
