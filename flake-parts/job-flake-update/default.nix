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
          self'.packages.action-ensure-tea-login
          self'.packages.action-create-pr
          self'.packages.action-flake-update
        ]
        ''
          bash ${./script.sh}
        '';
    in
    {
      packages.${name} = script;
    };
}
