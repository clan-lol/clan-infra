{ self, config, ... }:
{
  imports = [
    ./secrets.nix
    ./vars.nix
  ];

  perSystem =
    {
      system,
      self',
      pkgs,
      lib,
      ...
    }:
    {
      checks =
        let
          machinesPerSystem = {
            x86_64-linux = [
              "build-x86-01"
              "jitsi01"
              "storinator01"
              "web01"
              "web02"
            ];
            aarch64-linux = [
              "build01"
            ];
            aarch64-darwin = [
              "build02"
            ];
          };
          listedMachines = lib.sort lib.lessThan (lib.concatLists (lib.attrValues machinesPerSystem));
          actualMachines = lib.sort lib.lessThan (lib.attrNames config.clan.inventory.machines);
          machinesPerSystemCheck = pkgs.runCommand "machines-per-system-check" { } ''
            ${lib.optionalString (listedMachines != actualMachines) ''
              echo "machinesPerSystem out of sync with clan.inventory.machines:"
              echo "  listed: ${lib.concatStringsSep " " listedMachines}"
              echo "  actual: ${lib.concatStringsSep " " actualMachines}"
              exit 1
            ''}
            touch $out
          '';
          nixosMachines = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (
            lib.mapAttrs' (n: lib.nameValuePair "nixos-${n}") (
              lib.genAttrs (machinesPerSystem.${system} or [ ]) (
                name: self.nixosConfigurations.${name}.config.system.build.toplevel
              )
            )
          );
          darwinMachines = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin (
            lib.mapAttrs' (n: lib.nameValuePair "nix-darwin-${n}") (
              lib.genAttrs (machinesPerSystem.${system} or [ ]) (
                name: self.darwinConfigurations.${name}.config.system.build.toplevel
              )
            )
          );
          packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") self'.packages;
          devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") self'.devShells;
        in
        {
          inherit machinesPerSystemCheck;
        }
        // nixosMachines
        // darwinMachines
        // packages
        // devShells;
    };
}
