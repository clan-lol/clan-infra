{
  perSystem =
    { config
    , pkgs
    , ...
    }:
    let
      name = builtins.baseNameOf ./.;
      script = config.writers.writePureShellScriptBin
        name
        [
          pkgs.bash
          pkgs.coreutils
          pkgs.tea
        ]
        ''
          bash ${./script.sh}
        '';
    in
    {
      packages.${name} = script;
    };
}
