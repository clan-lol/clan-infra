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
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/merge-requests/445/merge";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-25_05.follows = "";
      inputs.flake-compat.follows = "flake-compat";
    };

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

    terranix.url = "github:terranix/terranix";
    terranix.inputs.flake-parts.follows = "flake-parts";
    terranix.inputs.nixpkgs.follows = "nixpkgs";

    jitsi-matrix-presence.url = "github:pinpox/jitsi-matrix-presence";
    jitsi-matrix-presence.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    niks3.url = "github:Mic92/niks3/tests";
    niks3.inputs.nixpkgs.follows = "nixpkgs";
    niks3.inputs.treefmt-nix.follows = "treefmt-nix";
    niks3.inputs.flake-parts.follows = "flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
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
      perSystem = {
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

          programs.deadnix.enable = true;
          programs.deadnix.priority = 1;
          programs.deadnix.no-lambda-arg = true;

          programs.statix.enable = true;
          programs.statix.priority = 2;

          programs.nixfmt.enable = true;
          programs.nixfmt.priority = 3;
          programs.nixfmt.excludes = [
            # generated files
            "node-env.nix"
            "node-packages.nix"
            "composition.nix"
          ];
        };
      };
    };
}
