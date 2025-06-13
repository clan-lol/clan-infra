{ self, ... }:
{
  perSystem =
    { inputs', pkgs, ... }:
    {
      checks = {
        # TODO: use `clan secrets key check` instead
        secrets =
          pkgs.runCommandNoCC "check-secrets"
            {
              nativeBuildInputs = [
                inputs'.clan-core.packages.default
                pkgs.nixVersions.latest
                pkgs.sops
              ];
            }
            ''
              ${inputs'.clan-core.legacyPackages.setupNixInNix}
              mkdir -p self
              cp -r --no-target-directory ${self} self
              CLAN_LOAD_AGE_PLUGINS=false clan secrets key update --flake self
              touch $out
            '';
      };
    };
}
