{
  perSystem =
    { inputs', pkgs, ... }:
    let
      convert2Tofu =
        provider:
        provider.override (prev: {
          homepage = builtins.replaceStrings [ "registry.terraform.io/providers" ] [
            "registry.opentofu.org"
          ] prev.homepage;
        });
    in
    {
      devShells.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.bashInteractive
          pkgs.sops

          inputs'.clan-core.packages.clan-cli

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
        ];
        inputsFrom = [ inputs'.clan-core.devShells.default ];
      };
    };
}
