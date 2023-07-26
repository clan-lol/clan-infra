{
  perSystem =
    { config
    , pkgs
    , self'
    , ...
    }:
    let
      name = builtins.baseNameOf ./.;
      script = config.writers.writePureShellScriptBin
        name
        [
          pkgs.bash
          pkgs.coreutils
          self'.packages.action-checkout
          self'.packages.action-flake-update
          self'.packages.action-create-pr
        ]
        ''
          bash ${./script.sh}
        '';
    in
    {
      packages.${name} = script;
    };
}
