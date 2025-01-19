{ self, inputs, ... }:
{
  imports = [
    inputs.terranix.flakeModule
  ];

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
    machines.jitsi01 = {
      imports = [ ./jitsi01/configuration.nix ];
    };
    inventory.services = {
      sshd.clan = {
        roles.server.tags = [ "all" ];
        roles.client.tags = [ "all" ];
      };
    };
  };

  perSystem =
    {
      inputs',
      system,
      pkgs,
      lib,
      ...
    }:
    {
      terranix = {
        terranixConfigurations.jitsi01 = {
          workdir = "targets/jitsi01";
          modules = [
            self.modules.terranix.base
            ./jitsi01/terraform-configuration.nix
          ];
          terraformWrapper.package = pkgs.opentofu.withPlugins (p: [
            p.external
            p.local
            p.hetznerdns
            p.null
            p.tls
            p.vultr
          ]);
          terraformWrapper.extraRuntimeInputs = [ inputs'.clan-core.packages.default ];
          terraformWrapper.prefixText = ''
            TF_VAR_passphrase=$(clan secrets get tf-passphrase)
            export TF_VAR_passphrase
          '';
        };
      };
    };
}
