{
  description = "Dependencies to deploy a clan";

  nixConfig = {
    extra-substituters = [ "https://cache.clan.lol" ];
    extra-trusted-public-keys = [ "cache.clan.lol-1:j83TYLUVsrSXZvQdMoY+Ms81Xd/nO8GNuQQHqphzRSg=" ];
  };

  inputs = {
    # https://github.com/NixOS/nixpkgs/pull/243252
    nixpkgs.url = "github:Mic92/nixpkgs/daemon";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "";

    srvos.url = "github:numtide/srvos";
    # Use the version of nixpkgs that has been tested to work with SrvOS
    srvos.inputs.nixpkgs.follows = "nixpkgs";

    nix.url = "github:/nixos/nix?ref=2.16.1";
    nix.inputs.nixpkgs.follows = "nixpkgs";
    nix.inputs.nixpkgs-regression.follows = "";
    nix.inputs.flake-compat.follows = "";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }: {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      imports = [
        inputs.treefmt-nix.flakeModule
        ./targets/flake-module.nix
        ./modules/flake-module.nix
      ];
      perSystem = { config, pkgs, inputs', ... }: {
        treefmt = {
          projectRootFile = "flake.nix";
          programs.terraform.enable = true;
          programs.nixpkgs-fmt.enable = true;
          settings.formatter.nixpkgs-fmt.excludes = [
            # generated files
            "node-env.nix"
            "node-packages.nix"
            "composition.nix"
          ];
        };
        packages = {
          default = pkgs.mkShell {
            packages = [
              pkgs.bashInteractive
              pkgs.sops
              (pkgs.terraform.withPlugins (p: [
                p.hetznerdns
                p.hcloud
                p.null
                p.external
                p.local
              ]))
            ];
          };
          inherit (pkgs.callPackage ./pkgs/renovate { }) renovate;
        } // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
          gitea = pkgs.callPackage ./pkgs/gitea { };
        };
      };
    });
}
