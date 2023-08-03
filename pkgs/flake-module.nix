{ ... }: {
  perSystem = { pkgs, config, ... }: {
    packages = {
      inherit (pkgs.callPackage ./renovate { }) renovate;
      gitea = pkgs.callPackage ./gitea { };

      action-checkout = pkgs.callPackage ./action-checkout {
        inherit (config.writers) writePureShellScriptBin;
      };
      action-create-pr = pkgs.callPackage ./action-create-pr {
        inherit (config.writers) writePureShellScriptBin;
      };
      action-ensure-tea-login = pkgs.callPackage ./action-ensure-tea-login {
        inherit (config.writers) writePureShellScriptBin;
      };
      action-flake-update = pkgs.callPackage ./action-flake-update {
        inherit (config.writers) writePureShellScriptBin;
      };
      action-flake-update-pr-clan = pkgs.callPackage ./action-flake-update-pr-clan {
        inherit (config.writers) writePureShellScriptBin;
        inherit (config.packages) action-checkout action-ensure-tea-login action-create-pr action-flake-update;
      };
      inherit (pkgs.callPackages ./job-flake-updates {
        inherit (config.writers) writePureShellScriptBin;
        inherit (config.packages) action-flake-update-pr-clan;
      }) job-flake-update-clan-core job-flake-update-clan-homepage job-flake-update-clan-infra;
    };
  };
}
