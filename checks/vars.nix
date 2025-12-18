{
  config,
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
      checks = lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
        vars =
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
          pkgs.runCommand "check-vars"
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
              ${lib.concatMapStringsSep "\n" (machine: ''
                clan vars check ${machine} --flake ./self --debug
                clan vars fix ${machine} --flake ./self --debug
              '') (lib.attrNames config.clan.inventory.machines)}
              touch $out
            '';
      };
    };
}
