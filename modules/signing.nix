{
  config,
  self,
  lib,
  ...
}:
let
  flake = import "${self}/flake.nix";

  # Read all public signing keys from the vars directory
  varsDir = "${self}/vars/per-machine";

  # Get all machine names from the vars directory
  machines = lib.attrNames (builtins.readDir varsDir);

  # Read public keys from all machines that have nix-signing-key
  allMachineSigningKeys = lib.flatten (
    map (
      machine:
      let
        keyPath = "${varsDir}/${machine}/nix-signing-key/key.pub/value";
      in
      lib.optional (builtins.pathExists keyPath) (lib.fileContents keyPath)
    ) machines
  );
in
{
  clan.core.vars.generators.nix-signing-key = {
    files."key" = { };
    files."key.pub".secret = false;
    runtimeInputs = [
      config.nix.package
    ];
    script = ''
      nix --extra-experimental-features "nix-command flakes" \
        key generate-secret --key-name ${config.networking.hostName}-1 > $out/key
      nix --extra-experimental-features "nix-command flakes" \
        key convert-secret-to-public < $out/key > $out/key.pub
    '';
  };

  nix.settings.secret-key-files = [
    config.clan.core.vars.generators.nix-signing-key.files."key".path
  ];

  # Trust all signing keys from all machines in the repository
  nix.settings.trusted-public-keys =
    allMachineSigningKeys ++ flake.nixConfig.extra-trusted-public-keys;

  nix.settings.substituters = flake.nixConfig.extra-substituters;
}
