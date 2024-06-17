{
  description = "Dependencies to deploy a clan";

  #nixConfig = {
  #  extra-substituters = [ "https://cache.clan.lol" ];
  #  extra-trusted-public-keys = [ "cache.clan.lol-1:3KztgSAB5R1M+Dz7vzkBGzXdodizbgLXGXKXlcQLA28=" ];
  #};

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
    };

    srvos.url = "github:numtide/srvos";
    # Use the version of nixpkgs that has been tested to work with SrvOS
    srvos.inputs.nixpkgs.follows = "nixpkgs";

    clan-core.url = "https://git.clan.lol/clan/clan-core/archive/matrix.tar.gz";
    clan-core.inputs.flake-parts.follows = "flake-parts";
    clan-core.inputs.nixpkgs.follows = "nixpkgs";
    clan-core.inputs.treefmt-nix.follows = "treefmt-nix";

    buildbot-nix.url = "github:Mic92/buildbot-nix";
    buildbot-nix.inputs.nixpkgs.follows = "nixpkgs";
    buildbot-nix.inputs.flake-parts.follows = "flake-parts";
    buildbot-nix.inputs.treefmt-nix.follows = "treefmt-nix";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { self, ... }:
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        imports = [
          inputs.treefmt-nix.flakeModule
          ./devShells/flake-module.nix
          ./targets/flake-module.nix
          ./modules/flake-module.nix
          ./pkgs/flake-module.nix
        ];
        perSystem = (
          {
            lib,
            self',
            system,
            ...
          }:
          {
            treefmt = {
              projectRootFile = ".git/config";
              programs.hclfmt.enable = true;
              programs.nixfmt-rfc-style.enable = true;
              settings.formatter.nixfmt-rfc-style.excludes = [
                # generated files
                "node-env.nix"
                "node-packages.nix"
                "composition.nix"
              ];
            };
            checks =
              let
                nixosMachines = lib.mapAttrs' (
                  name: config: lib.nameValuePair "nixos-${name}" config.config.system.build.toplevel
                ) ((lib.filterAttrs (_: config: config.pkgs.system == system)) self.nixosConfigurations);
                packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") self'.packages;
                devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") self'.devShells;
                homeConfigurations = lib.mapAttrs' (
                  name: config: lib.nameValuePair "home-manager-${name}" config.activation-script
                ) (self'.legacyPackages.homeConfigurations or { });
              in
              nixosMachines // packages // devShells // homeConfigurations;
          }
        );
      }
    );
}
