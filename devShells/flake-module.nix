{ self, ... }:
{
  perSystem =
    {
      config,
      inputs',
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.bash
          pkgs.sops

          pkgs.nixVersions.latest

          inputs'.clan-core.packages.tea-create-pr
          inputs'.clan-core.packages.merge-after-ci
          inputs'.clan-core.packages.clan-cli

          # treefmt with config defined in ./flake.nix
          config.treefmt.build.wrapper

          self.nixosConfigurations.web02.config.services.kanidm.package
        ];
        env.KANIDM_URL = "https://idm.thecomputer.co";
      };
    };
}
