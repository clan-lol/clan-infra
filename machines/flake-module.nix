{ self, inputs, ... }:
{
  imports = [
    inputs.terranix.flakeModule
  ];

  clan = {
    meta.name = "infra";
    # Make flake available in modules
    specialArgs = { inherit self; };
    inherit self;
    inventory.machines.build02.machineClass = "darwin";
    inventory.services = {
      zerotier.claninfra = {
        roles.controller.machines = [ "web01" ];
        roles.controller.extraModules = [
          "modules/zerotier.nix"
        ];
        roles.moon.machines = [
          "jitsi01"
          "web01"
        ];
        machines.jitsi01.config = {
          # jitsi.clan.lol
          moon.stableEndpoints = [
            "207.148.120.82"
            "2401:c080:1400:5439:5400:5ff:fe43:3de5"
          ];
        };
        machines.web01.config = {
          # clan.lol
          moon.stableEndpoints = [
            "23.88.17.207"
            "2a01:4f8:2220:1565::1"
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

    secrets.age.plugins = [
      "age-plugin-1p"
    ];
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
          # `nix run .#dns` will fail
          # This is used as a module from the `terraform` terranix config
          terranixConfigurations.dns = {
            workdir = "terraform";
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

          terranixConfigurations.terraform = {
            workdir = "terraform";
            modules = [
              self.modules.terranix.base
              self.modules.terranix.with-dns
              self.modules.terranix.vultr
              ./build01/terraform-configuration.nix
              ./demo01/terraform-configuration.nix
              ./jitsi01/terraform-configuration.nix
            ];
            terraformWrapper.package = package;
            terraformWrapper.extraRuntimeInputs = [ inputs'.clan-core.packages.default ];
            terraformWrapper.prefixText = ''
              TF_VAR_passphrase=$(clan secrets get tf-passphrase)
              export TF_VAR_passphrase
              TF_ENCRYPTION=$(cat <<EOF
              key_provider "pbkdf2" "state_encryption_password" {
                passphrase = "$TF_VAR_passphrase"
              }
              method "aes_gcm" "encryption_method" {
                keys = "\''${key_provider.pbkdf2.state_encryption_password}"
              }
              state {
                enforced = true
                method = "\''${method.aes_gcm.encryption_method}"
              }
              EOF
              )

              # shellcheck disable=SC2090
              export TF_ENCRYPTION
            '';
          };
        };
    };
}
