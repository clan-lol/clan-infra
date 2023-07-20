{ pkgs, inputs }:
let
  # FIXME get rid of nix input?
  base = import (inputs.nix + "/docker.nix") {
    inherit pkgs;
    name = "nix-ci-base";
    maxLayers = 10;
    extraPkgs = with pkgs; [
      nodejs_20 # nodejs is needed for running most 3rdparty actions
      # add any other pre-installed packages here
    ];
    # do we want this at all?
    channelURL = "https://nixos.org/channels/nixpkgs-unstable";
    nixConf = {
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
        # insert any other binary caches here
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        # insert the public keys for those binary caches here
      ];
      # allow using the new flake commands in our workflows
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
in
pkgs.dockerTools.buildImage {
  name = "nix-runner";
  tag = "latest";

  fromImage = base;
  fromImageName = null;
  fromImageTag = "latest";

  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = [ pkgs.coreutils-full ];
    pathsToLink = [ "/bin" ]; # add coreutuls (which includes sleep) to /bin
  };
}
