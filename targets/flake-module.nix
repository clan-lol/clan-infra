{ self, inputs, ... }:
{
  flake = inputs.clan-core.lib.buildClan {
    meta.name = "infra";
    directory = self;
    # Make flake available in modules
    specialArgs = {
      self = {
        inherit (self) inputs nixosModules packages;
      };
    };
    machines = {
      web01 = { modulesPath, ... }: {
        imports = [ (./web01/configuration.nix) ];
      };
    };
  };
}
