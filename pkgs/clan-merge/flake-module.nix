{
  perSystem = { pkgs, ... }:
    let
      package = pkgs.callPackage ./default.nix { inherit pkgs; };
    in
    {
      packages.clan-merge = package;
      checks.clan-merge = package.tests.check;
      devShells.clan-merge = import ./shell.nix { inherit pkgs; };
    };
}
