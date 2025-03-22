{
  description = "Dependencies to deploy a clan";

  nixConfig = {
    extra-substituters = [ "https://cache.clan.lol" ];
    extra-trusted-public-keys = [ "cache.clan.lol-1:3KztgSAB5R1M+Dz7vzkBGzXdodizbgLXGXKXlcQLA28=" ];
  };

  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?ref=nixpkgs-unstable&shallow=1";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-24_11.follows = "";
      inputs.flake-compat.follows = "flake-compat";
    };

    srvos.url = "github:nix-community/srvos";
    srvos.inputs.nixpkgs.follows = "nixpkgs";

    clan-core.url = "git+https://git.clan.lol/clan/clan-core?ref=main&shallow=1";
    clan-core.inputs.flake-parts.follows = "flake-parts";
    clan-core.inputs.nixpkgs.follows = "nixpkgs";
    clan-core.inputs.treefmt-nix.follows = "treefmt-nix";

    # Use Nix 2.26 inside buildbot-worker
    buildbot-nix.url = "github:nix-community/buildbot-nix/pull/404/merge";
    buildbot-nix.inputs.nixpkgs.follows = "nixpkgs";
    buildbot-nix.inputs.flake-parts.follows = "flake-parts";
    buildbot-nix.inputs.treefmt-nix.follows = "treefmt-nix";

    # OpenTofu support
    # https://github.com/pedorich-n/terranix/pull/1
    # https://github.com/terranix/terranix/pull/115
    # https://github.com/terranix/terranix/pull/116
    terranix.url = "github:Enzime/terranix/terranix-plus";
    terranix.inputs.bats-assert.follows = "";
    terranix.inputs.bats-support.follows = "";
    terranix.inputs.flake-parts.follows = "flake-parts";
    terranix.inputs.nixpkgs.follows = "nixpkgs";
    terranix.inputs.terranix-examples.follows = "";

    jitsi-matrix-presence.url = "github:pinpox/jitsi-matrix-presence";
    jitsi-matrix-presence.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { self, ... }:
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];
        imports = [
          inputs.clan-core.flakeModules.default
          inputs.treefmt-nix.flakeModule
          ./devShells/flake-module.nix
          ./machines/flake-module.nix
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
              programs.terraform.enable = true;
              programs.shellcheck.enable = true;

              programs.deno.enable = true;

              programs.ruff.check = true;
              programs.ruff.format = true;
              programs.yamlfmt.enable = true;

              settings.global.excludes = [
                # generated files
                "sops/*"
                "terraform.tfstate"
                "*.tfvars.sops.json"
                "*nixos-vars.json"
                "secrets.yaml"
                "facter.json"
                "secrets.auto.tfvars.sops.json"
              ];

              programs.nixfmt.enable = true;
              settings.formatter.nixfmt.excludes = [
                # generated files
                "node-env.nix"
                "node-packages.nix"
                "composition.nix"
              ];
            };
            checks =
              let
                machinesPerSystem = {
                  x86_64-linux = [
                    "demo01"
                    "jitsi01"
                    "storinator01"
                    "web01"
                  ];
                  aarch64-linux = [
                    "build01"
                  ];
                };
                nixosMachines = lib.mapAttrs' (n: lib.nameValuePair "nixos-${n}") (
                  lib.genAttrs (machinesPerSystem.${system} or [ ]) (
                    name: self.nixosConfigurations.${name}.config.system.build.toplevel
                  )
                );
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
