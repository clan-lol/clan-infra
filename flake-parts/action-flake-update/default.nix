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
          pkgs.git
          pkgs.nix
        ]
        ''
          bash ${./script.sh}
        '';
    in
    {
      packages.${name} = script;
    };
}
