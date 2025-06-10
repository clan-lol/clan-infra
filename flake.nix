{
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

    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-25_05.follows = "";
      inputs.flake-compat.follows = "flake-compat";
    };

    # To test the cgroup fix: https://github.com/Mic92/nix-1/commit/fa1f677653c5d1ae910b5908ea1efb0ff909e9c9
    nix.url = "git+https://github.com/Mic92/nix-1?shallow=1";
    nix.inputs.nixpkgs.follows = "nixpkgs";
    nix.inputs.flake-parts.follows = "";
    nix.inputs.flake-compat.follows = "";
    nix.inputs.nixpkgs-regression.follows = "";
    nix.inputs.git-hooks-nix.follows = "";
    nix.inputs.nixpkgs-23-11.follows = "";

    srvos.url = "github:nix-community/srvos";
    srvos.inputs.nixpkgs.follows = "nixpkgs";

    clan-core.url = "git+https://git.clan.lol/clan/clan-core?ref=main&shallow=1";
    clan-core.inputs.flake-parts.follows = "flake-parts";
    clan-core.inputs.nixpkgs.follows = "nixpkgs";
    clan-core.inputs.nix-darwin.follows = "nix-darwin";
    clan-core.inputs.treefmt-nix.follows = "treefmt-nix";

    buildbot-nix.url = "github:nix-community/buildbot-nix";
    buildbot-nix.inputs.nixpkgs.follows = "nixpkgs";
    buildbot-nix.inputs.flake-parts.follows = "flake-parts";
    buildbot-nix.inputs.treefmt-nix.follows = "treefmt-nix";

    # Fix `devShells` failing to build on latest HEAD
    # https://github.com/terranix/terranix/pull/125
    terranix.url = "github:terranix/terranix/pull/125/merge";
    terranix.inputs.flake-parts.follows = "flake-parts";
    terranix.inputs.nixpkgs.follows = "nixpkgs";

    jitsi-matrix-presence.url = "github:pinpox/jitsi-matrix-presence";
    jitsi-matrix-presence.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    renovate.url = "github:Mic92/renovate";
    renovate.inputs.nixpkgs.follows = "nixpkgs";
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

        # Hacky way to detect we're in a REPL
        debug = builtins ? currentSystem;

        imports = [
          inputs.clan-core.flakeModules.default
          inputs.treefmt-nix.flakeModule

          ./checks/flake-module.nix
          ./devShells/flake-module.nix
          ./machines/flake-module.nix
          ./modules/flake-module.nix
          ./pkgs/flake-module.nix
        ];
        perSystem = (
          {
            lib,
            self',
            pkgs,
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
          }
        );
      }
    );
}
