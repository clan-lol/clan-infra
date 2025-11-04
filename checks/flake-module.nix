{ self, ... }:
{
  imports = [ ./secrets.nix ];

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
              "demo01"
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
        nixosMachines // darwinMachines // homeConfigurations // packages // devShells;
    };
}
