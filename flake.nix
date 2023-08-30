{
  description = "Dependencies to deploy a clan";

  nixConfig = {
    extra-substituters = [ "https://cache.clan.lol" ];
    extra-trusted-public-keys = [ "cache.clan.lol-1:j83TYLUVsrSXZvQdMoY+Ms81Xd/nO8GNuQQHqphzRSg=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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

    clan-core.url = "git+https://git.clan.lol/clan/clan-core";
    clan-core.inputs.flake-parts.follows = "flake-parts";
    clan-core.inputs.nixpkgs.follows = "nixpkgs";
    clan-core.inputs.treefmt-nix.follows = "treefmt-nix";
    clan-core.inputs.sops-nix.follows = "sops-nix";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
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
      perSystem = {
        treefmt = {
          projectRootFile = ".git/config";
          programs.terraform.enable = true;
          programs.nixpkgs-fmt.enable = true;
          settings.formatter.nixpkgs-fmt.excludes = [
            # generated files
            "node-env.nix"
            "node-packages.nix"
            "composition.nix"
          ];
        };
      };
    };
}
