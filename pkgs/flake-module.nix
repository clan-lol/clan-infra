{ self, ... }:
{
  imports = [
  ];
  perSystem =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      packages =
        let
          writers = pkgs.callPackage ./writers.nix { };
          web01 = self.nixosConfigurations.web01.config;
        in
        {
          gitea = pkgs.callPackage ./gitea { };

          spam-test = pkgs.callPackage ./spam-test {
            inherit (web01.mailserver) fqdn;
            control = "infra@clan.lol";
            # The sieve that unconditionally files into INBOX is what makes a
            # mailbox unfiltered, so reading it back is the shipping truth
            # rather than a second list to keep in sync.
            unfiltered = lib.attrNames (
              lib.filterAttrs (
                _: acct: acct.sieveScript != null && lib.hasInfix ''fileinto "INBOX";'' acct.sieveScript
              ) web01.mailserver.accounts
            );
          };

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
          action-flake-update-pr-clan-individual = pkgs.callPackage ./action-flake-update-pr-clan-individual {
            inherit (writers) writePureShellScriptBin;
            inherit (config.packages) action-ensure-tea-login action-create-pr action-flake-update;
          };
          inherit
            (pkgs.callPackages ./job-flake-updates {
              inherit (writers) writePureShellScriptBin;
              inherit (config.packages) action-flake-update-pr-clan action-flake-update-pr-clan-individual;
            })
            job-flake-update-clan-core
            job-flake-update-clan-core-individual
            job-flake-update-clan-homepage
            job-flake-update-clan-infra
            job-flake-update-data-mesher
            ;
        };
    };
}
