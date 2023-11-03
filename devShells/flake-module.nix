{
  perSystem =
    { inputs'
    , pkgs
    , lib
    , ...
    }: {
      devShells.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.bashInteractive
          pkgs.sops

          inputs'.clan-core.packages.clan-cli

          ((pkgs.terraform.withPlugins (p: [
            p.hetznerdns
            p.hcloud
            p.null
            p.external
            p.local
          ])).overrideAttrs (old: {
            meta = old.meta // { license = lib.licenses.free; };
          }))
        ];
        inputsFrom = [
          inputs'.clan-core.devShells.default
        ];
      };
    };
}
