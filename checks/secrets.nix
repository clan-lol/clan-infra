{
  self,
  inputs,
  ...
}:
{
  perSystem =
    {
      inputs',
      pkgs,
      lib,
      ...
    }:
    {
      # TODO: use `clan secrets key check` instead
      # Skip on Darwin: diverted stores are not supported on macOS
      checks = lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
        secrets =
          let
            # Recursively collect all flake inputs including transitive ones
            allInputPaths = map (x: x.key) (
              lib.genericClosure {
                startSet = lib.mapAttrsToList (_: input: {
                  key = input.outPath or input;
                  inherit input;
                }) inputs;
                operator =
                  { input, ... }:
                  lib.mapAttrsToList (_: i: {
                    key = i.outPath or i;
                    input = i;
                  }) (input.inputs or { });
              }
            );
          in
          pkgs.runCommand "check-secrets"
            {
              nativeBuildInputs = [
                inputs'.clan-core.packages.default
                pkgs.nixVersions.latest
                pkgs.sops
              ];
              env.closureInfo = pkgs.closureInfo { rootPaths = allInputPaths; };
            }
            ''
              ${inputs'.clan-core.legacyPackages.setupNixInNix}
              mkdir -p self
              cp -r --no-target-directory ${self} self
              CLAN_LOAD_AGE_PLUGINS=false clan secrets key update --flake ./self
              touch $out
            '';
      };
    };
}
