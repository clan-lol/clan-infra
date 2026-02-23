{
  nixConfig = {
    extra-substituters = [ "https://cache.clan.lol" ];
    extra-trusted-public-keys = [
      "cache.clan.lol-1:3KztgSAB5R1M+Dz7vzkBGzXdodizbgLXGXKXlcQLA28="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?ref=nixpkgs-unstable&shallow=1";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Test https://github.com/nix-darwin/nix-darwin/pull/1701
    # and https://github.com/nix-darwin/nix-darwin/pull/1702
    nix-darwin.url = "github:Enzime/nix-darwin/1701+1702";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-1.url = "git+https://github.com/Mic92/nix-1?shallow=1";
    nix-1.inputs.nixpkgs.follows = "nixpkgs";
    nix-1.inputs.flake-parts.follows = "";
    nix-1.inputs.flake-compat.follows = "";
    nix-1.inputs.nixpkgs-regression.follows = "";
    nix-1.inputs.git-hooks-nix.follows = "";
    nix-1.inputs.nixpkgs-23-11.follows = "";

    nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
      inputs.git-hooks.follows = "";
    };

    srvos.url = "github:nix-community/srvos";
    srvos.inputs.nixpkgs.follows = "nixpkgs";

    clan-core.url = "git+https://git.clan.lol/clan/clan-core?ref=main&shallow=1";
    clan-core.inputs.flake-parts.follows = "flake-parts";
    clan-core.inputs.nixpkgs.follows = "nixpkgs";
    clan-core.inputs.nix-darwin.follows = "nix-darwin";
    clan-core.inputs.treefmt-nix.follows = "treefmt-nix";

    # Test https://github.com/nix-community/buildbot-nix/pull/548
    # and https://github.com/Enzime/buildbot-nix/tree/claude/fix-gitea-build-status-5GQ0K
    buildbot-nix.url = "github:Enzime/buildbot-nix/push-ottkyuyywqzt";
    buildbot-nix.inputs.nixpkgs.follows = "nixpkgs";
    buildbot-nix.inputs.flake-parts.follows = "flake-parts";
    buildbot-nix.inputs.treefmt-nix.follows = "treefmt-nix";

    terranix.url = "github:terranix/terranix";
    terranix.inputs.flake-parts.follows = "flake-parts";
    terranix.inputs.nixpkgs.follows = "nixpkgs";

    jitsi-matrix-presence.url = "github:pinpox/jitsi-matrix-presence";
    jitsi-matrix-presence.inputs.nixpkgs.follows = "nixpkgs";

    gitea-mq.url = "github:Mic92/gitea-mq/pull/14/merge";
    gitea-mq.inputs.nixpkgs.follows = "nixpkgs";
    gitea-mq.inputs.flake-parts.follows = "flake-parts";
    gitea-mq.inputs.treefmt-nix.follows = "treefmt-nix";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    niks3.url = "github:Mic92/niks3/rate-limit";
    niks3.inputs.nixpkgs.follows = "nixpkgs";
    niks3.inputs.treefmt-nix.follows = "treefmt-nix";
    niks3.inputs.flake-parts.follows = "flake-parts";

    nixpkgs-terraform-providers-bin.url = "github:nix-community/nixpkgs-terraform-providers-bin";
    nixpkgs-terraform-providers-bin.inputs.nixpkgs.follows = "nixpkgs";
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
