{
  description = "Dependencies to deploy a clan";

  inputs = {
    # https://github.com/NixOS/nixpkgs/pull/241526
    nixpkgs.url = "github:Mic92/nixpkgs/cloud-init";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    homepage.url = "git+https://git.clan.lol/clan/clan-homepage";
    homepage.inputs.nixpkgs.follows = "nixpkgs";
    homepage.inputs.flake-parts.follows = "flake-parts";


    srvos.url = "github:numtide/srvos";
    # Use the version of nixpkgs that has been tested to work with SrvOS
    srvos.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }: {
      systems = lib.systems.flakeExposed;
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
        };
        packages.default = pkgs.mkShell {
          packages = [
            pkgs.bashInteractive
            pkgs.sops
            (pkgs.terraform.withPlugins (p: [
              p.namecheap
              p.netlify
              p.hcloud
              p.null
              p.external
              p.local
            ]))
          ];
        };
      };
    });
}
