{ config, ... }:
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
}
