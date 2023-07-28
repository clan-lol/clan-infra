{
  perSystem =
    { inputs'
    , lib
    , pkgs
    , self'
    , ...
    }: {
      devShells.default = pkgs.mkShell {
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
        inputsFrom = [
          inputs'.clan-core.devShells.default
        ];
      };
    };
}
