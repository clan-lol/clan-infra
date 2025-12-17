{ self, ... }:
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
          listedNixosMachines = lib.sort lib.lessThan (
            lib.concatLists (
              lib.attrValues (lib.filterAttrs (s: _: lib.hasSuffix "-linux" s) machinesPerSystem)
            )
          );
          listedDarwinMachines = lib.sort lib.lessThan (
            lib.concatLists (
              lib.attrValues (lib.filterAttrs (s: _: lib.hasSuffix "-darwin" s) machinesPerSystem)
            )
          );
          actualNixosMachines = lib.sort lib.lessThan (lib.attrNames (self.nixosConfigurations or { }));
          actualDarwinMachines = lib.sort lib.lessThan (lib.attrNames (self.darwinConfigurations or { }));
          machinesPerSystemCheck = pkgs.runCommand "machines-per-system-check" { } ''
            ${lib.optionalString (listedNixosMachines != actualNixosMachines) ''
              echo "machinesPerSystem out of sync with nixosConfigurations:"
              echo "  listed: ${lib.concatStringsSep " " listedNixosMachines}"
              echo "  actual: ${lib.concatStringsSep " " actualNixosMachines}"
              exit 1
            ''}
            ${lib.optionalString (listedDarwinMachines != actualDarwinMachines) ''
              echo "machinesPerSystem out of sync with darwinConfigurations:"
              echo "  listed: ${lib.concatStringsSep " " listedDarwinMachines}"
              echo "  actual: ${lib.concatStringsSep " " actualDarwinMachines}"
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
          homeConfigurations =
            lib.mapAttrs' (name: config: lib.nameValuePair "home-manager-${name}" config.activationPackage)
              (
                lib.filterAttrs (_: config: config.pkgs.stdenv.hostPlatform.system == system) (
                  self.homeConfigurations or { }
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
        // homeConfigurations
        // packages
        // devShells;
    };
}
