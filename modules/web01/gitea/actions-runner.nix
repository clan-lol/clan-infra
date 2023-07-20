{ config, self, pkgs, lib, ... }:
{
  systemd.services.gitea-runner-nix-image = {
    wantedBy = [ "multi-user.target" ];
    after = [ "podman.service" ];
    requires = [ "podman.service" ];
    path = [ pkgs.podman pkgs.gnutar ];
    script = ''
      tar cv --files-from /dev/null | podman import - scratch
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

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
      "gitea-runner-nix-image.service"
    ];
    requires = [
      "gitea-runner-nix-token.service"
      "gitea-runner-nix-image.service"
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
    };
  };

  services.gitea-actions-runner.instances.nix =
    let
      bin = pkgs.runCommand "extra-bins" { } ''
        mkdir -p $out
        for dir in ${toString [ pkgs.coreutils pkgs.git pkgs.nix pkgs.bash pkgs.jq pkgs.nodejs]}; do
          for bin in "$dir"/bin/*; do
            ln -s "$bin" "$out/$(basename "$bin")"
          done
        done
      '';
      etc = pkgs.runCommand "etc" { } ''
        mkdir -p $out/etc/nix

        cat <<NIX_CONFIG > $out/etc/nix.conf
        accept-flake-config = true
        experimental-features = nix-command flakes
        NIX_CONFIG

        # Create an unpriveleged user that we can use also without the run-as-user.sh script
        touch $out/etc/passwd $out/etc/group
        ${pkgs.buildPackages.shadow}/bin/groupadd --prefix $out -g 9000 nixuser
        ${pkgs.buildPackages.shadow}/bin/useradd --prefix $out -m -d /tmp -u 9000 -g 9000 -G nixuser nixuser

        # Add SSL CA certs
        mkdir -p $out/etc/ssl/certs
        cp -a "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" $out/etc/ssl/certs/ca-bundle.crt
      '';
    in
    {
      enable = true;
      name = "nix-runner";
      # take the git root url from the gitea config
      # only possible if you've also configured your gitea though the same nix config
      # otherwise you need to set it manually
      url = config.services.gitea.settings.server.ROOT_URL;
      # use your favourite nix secret manager to get a path for this
      tokenFile = "/var/lib/gitea-registration/token";
      labels = [ "nix:docker://scratch" ];
      settings = {
        container.options = "-e NIX_BUILD_SHELL=/bin/bash -e PAGER=cat -e PATH=/bin -e SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt -v /tmp:/tmp -v /nix:/nix -v ${etc}/etc:/etc -v ${bin}:/bin --user nixuser";
        container.valid_volumes = [
          "/nix"
          "/tmp"
          bin
          "${etc}/etc"
        ];
      };
    };
}
