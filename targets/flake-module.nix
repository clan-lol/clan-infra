{ self, inputs, ... }:
{
  clan = {
    meta.name = "infra";
    # Make flake available in modules
    specialArgs.self = {
      inherit (self) inputs nixosModules packages;
    };
    directory = self;
    machines.web01 = {
      imports = [ ./web01/configuration.nix ];
    };
  };
}
