{ lib, inputs, ... }: {
  perSystem = { pkgs, inputs', ... }: {
    packages = {
      inherit (pkgs.callPackage ./renovate { }) renovate;
    } // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
      gitea = pkgs.callPackage ./gitea { };
      actions-runner = pkgs.callPackage ./actions-runner.nix {
        inherit inputs;
      };
    };
  };
}
