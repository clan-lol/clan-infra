{ config, self, ... }:
let
  flake = import "${self}/flake.nix";
in
{
  clan.core.vars.generators.nix-signing-key = {
    files."key" = { };
    files."key.pub".secret = false;
    runtimeInputs = [
      config.nix.package
    ];
    script = ''
      nix key generate-secret --key-name ${config.networking.hostName}-1 > $out/key
      nix key convert-secret-to-public < $out/key > $out/key.pub
    '';
  };

  nix.settings.secret-key-files = [
    config.clan.core.vars.generators.nix-signing-key.files."key".path
  ];

  nix.settings.trusted-public-keys = [
    # trust our own key, this is useful if we reinstall the machine and someone sends us back our own package
    config.clan.core.vars.generators.nix-signing-key.files."key.pub".value
  ] ++ flake.nixConfig.extra-trusted-public-keys;

  nix.settings.substituters = flake.nixConfig.extra-substituters;
}
