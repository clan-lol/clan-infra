{
  imports = [
    ./clan-merge/flake-module.nix
    ./matrix-bot/flake-module.nix
  ];
  perSystem =
    { pkgs, config, ... }:
    {
      packages =
        let
          writers = pkgs.callPackage ./writers.nix { };
        in
        {
          gitea = pkgs.callPackage ./gitea { };

          action-create-pr = pkgs.callPackage ./action-create-pr {
            inherit (writers) writePureShellScriptBin;
          };
          action-ensure-tea-login = pkgs.callPackage ./action-ensure-tea-login {
            inherit (writers) writePureShellScriptBin;
          };
          action-flake-update = pkgs.callPackage ./action-flake-update {
            inherit (writers) writePureShellScriptBin;
          };
          action-flake-update-pr-clan = pkgs.callPackage ./action-flake-update-pr-clan {
            inherit (writers) writePureShellScriptBin;
            inherit (config.packages) action-ensure-tea-login action-create-pr action-flake-update;
          };
          inherit
            (pkgs.callPackages ./job-flake-updates {
              inherit (writers) writePureShellScriptBin;
              inherit (config.packages) action-flake-update-pr-clan;
            })
            job-flake-update-clan-core
            job-flake-update-clan-homepage
            job-flake-update-clan-infra
            job-flake-update-data-mesher
            ;
        };
    };
}
