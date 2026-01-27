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
    let
      # Closure of all flake inputs needed for evaluation
      flakeInputsClosure = pkgs.closureInfo {
        rootPaths = builtins.attrValues (
          removeAttrs inputs [
            "self"
          ]
        );
      };
    in
    {
      # TODO: use `clan secrets key check` instead
      # Skip on Darwin: diverted stores are not supported on macOS
      checks = lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
        secrets =
          pkgs.runCommand "check-secrets"
            {
              nativeBuildInputs = [
                inputs'.clan-core.packages.default
                pkgs.nixVersions.latest
                pkgs.sops
              ];
              closureInfo = flakeInputsClosure;
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
