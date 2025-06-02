{
  perSystem =
    {
      config,
      inputs',
      pkgs,
      ...
    }:
    let
      convert2Tofu =
        provider:
        provider.override (prev: {
          homepage =
            builtins.replaceStrings
              [ "registry.terraform.io/providers" ]
              [
                "registry.opentofu.org"
              ]
              prev.homepage;
        });
    in
    {
      devShells.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.bash
          pkgs.sops

          pkgs.nixVersions.latest

          inputs'.clan-core.packages.tea-create-pr
          inputs'.clan-core.packages.merge-after-ci
          inputs'.clan-core.packages.clan-cli

          # treefmt with config defined in ./flake.nix
          config.treefmt.build.wrapper

          (pkgs.opentofu.withPlugins (
            p:
            builtins.map convert2Tofu [
              p.hetznerdns
              p.hcloud
              p.null
              p.external
              p.local
            ]
          ))

          pkgs.kanidm_1_6
        ];
        env.KANIDM_URL = "https://idm.thecomputer.co";
      };
    };
}
