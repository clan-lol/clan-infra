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
    inventory.services = {
      zerotier.claninfra = {
        roles.controller.machines = [ "web01" ];
        roles.controller.extraModules = [
          "modules/zerotier.nix"
        ];
        roles.moon.machines = [
          "jitsi01"
        ];
        machines.jitsi01.config = {
          # jitsi.clan.lol
          moon.stableEndpoints = [
            "207.148.120.82"
            "2401:c080:1400:5439:5400:5ff:fe43:3de5"
          ];
        };
        roles.peer.tags = [ "all" ];
      };
      sshd.clan = {
        roles.server.tags = [ "all" ];
        roles.client.tags = [ "all" ];
        config.certificate.searchDomains = [ "clan.lol" ];
      };
    };
  };

  perSystem =
    {
      inputs',
      config,
      pkgs,
      ...
    }:
    {
      terranix =
        let
          package = pkgs.opentofu.withPlugins (p: [
            p.external
            p.local
            p.hetznerdns
            p.null
            p.tls
            p.vultr
          ]);
        in
        {
          terranixConfigurations.dns = {
            workdir = "targets/jitsi01";
            modules = [
              self.modules.terranix.base
              self.modules.terranix.dns
            ];
            terraformWrapper.package = package;
            terraformWrapper.extraRuntimeInputs = [ inputs'.clan-core.packages.default ];
            terraformWrapper.prefixText = ''
              TF_VAR_passphrase=$(clan secrets get tf-passphrase)
              export TF_VAR_passphrase
            '';
          };

          terranixConfigurations.jitsi01 = {
            workdir = "targets/jitsi01";
            modules = [
              self.modules.terranix.base
              ./jitsi01/terraform-configuration.nix
            ];
            extraArgs = {
              config' = config;
            };
            terraformWrapper.package = package;
            terraformWrapper.extraRuntimeInputs = [ inputs'.clan-core.packages.default ];
            terraformWrapper.prefixText = ''
              TF_VAR_passphrase=$(clan secrets get tf-passphrase)
              export TF_VAR_passphrase
            '';
          };
        };
    };
}
