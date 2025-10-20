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
    inventory.instances = {
      emergency-access = {
        module = {
          name = "emergency-access";
          input = "clan-core";
        };

        roles.default.tags."all" = { };
      };
      users-root = {
        module = {
          name = "users";
          input = "clan-core";
        };
        roles.default.tags."all" = { };
        roles.default.settings = {
          user = "root";
          prompt = false;
          groups = [ ];
        };
      };
      zerotier-claninfra = {
        module = {
          name = "zerotier";
          input = "clan-core";
        };
        roles.controller.machines.web01 = { };
        roles.controller.extraModules = [ ../modules/zerotier.nix ];
        roles.moon.machines.jitsi01.settings = {
          # jitsi.clan.lol
          stableEndpoints = [
            "207.148.120.82"
            "2401:c080:1400:5439:5400:5ff:fe43:3de5"
          ];
        };
        roles.moon.machines.web01.settings = {
          # clan.lol
          stableEndpoints = [
            "23.88.17.207"
            "2a01:4f8:2220:1565::1"
          ];
        };
        roles.peer.tags.all = { };
      };
      sshd-clan = {
        module = {
          name = "sshd";
          input = "clan-core";
        };
        roles.server.tags.all = { };
        roles.server.settings = {
          certificate.searchDomains = [ "clan.lol" ];
        };
        roles.server.machines.web01.settings = {
          hostKeys.rsa.enable = true;
        };
        roles.client.tags.all = { };
        # searchDomains automatically inherited from all servers in the instance
      };
      matrix-synapse = {
        module = {
          name = "matrix-synapse";
          input = "clan-core";
        };
        roles.default.machines.web01 = { };
        roles.default.settings = {
          app_domain = "matrix.clan.lol";
          server_tld = "clan.lol";
          acmeEmail = "admins@clan.lol";

          users = {
            admin = {
              admin = true;
            };
            monitoring = { };
            clan-bot = { };
            w = { };
            toastal = { };
          };
        };
      };
    };

    secrets.age.plugins = [
      "age-plugin-1p"
      "age-plugin-se"
    ];
  };

  perSystem =
    {
      inputs',
      pkgs,
      ...
    }:
    {
      terranix =
        let
          package = pkgs.opentofu.withPlugins (p: [
            p.hashicorp_external
            p.hashicorp_local
            p.timohirt_hetznerdns
            p.hashicorp_null
            p.hashicorp_tls
            p.vultr_vultr
          ]);
          cachePackage = pkgs.opentofu.withPlugins (p: [
            p.hashicorp_external
            p.fastly_fastly
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
              ./web01/terraform-configuration.nix
              ./web02/terraform-configuration.nix
            ];
            terraformWrapper.package = package;
            terraformWrapper.extraRuntimeInputs = [ inputs'.clan-core.packages.default ];
            terraformWrapper.prefixText = ''
              TF_VAR_passphrase=$(clan secrets get tf-passphrase)
              export TF_VAR_passphrase
              TF_ENCRYPTION=$(cat <<'EOF'
              key_provider "pbkdf2" "state_encryption_password" {
                passphrase = var.passphrase
              }
              method "aes_gcm" "encryption_method" {
                keys = key_provider.pbkdf2.state_encryption_password
              }
              state {
                enforced = true
                method = method.aes_gcm.encryption_method
              }
              EOF
              )

              # shellcheck disable=SC2090
              export TF_ENCRYPTION
            '';
          };

          # Separate Fastly cache configuration
          terranixConfigurations.cache = {
            workdir = "terraform-cache";
            modules = [
              self.modules.terranix.cache
            ];
            terraformWrapper.package = cachePackage;
            terraformWrapper.extraRuntimeInputs = [ inputs'.clan-core.packages.default ];
            terraformWrapper.prefixText = ''
              TF_VAR_passphrase=$(clan secrets get tf-passphrase)
              export TF_VAR_passphrase
              TF_ENCRYPTION=$(cat <<'EOF'
              key_provider "pbkdf2" "state_encryption_password" {
                passphrase = var.passphrase
              }
              method "aes_gcm" "encryption_method" {
                keys = key_provider.pbkdf2.state_encryption_password
              }
              state {
                enforced = true
                method = method.aes_gcm.encryption_method
              }
              EOF
              )

              # shellcheck disable=SC2090
              export TF_ENCRYPTION
            '';
          };

          # Separate Fastly cache configuration for cache.clan.lol
          terranixConfigurations.cache-new = {
            workdir = "terraform-cache-new";
            modules = [
              self.modules.terranix.cache-new
            ];
            terraformWrapper.package = cachePackage;
            terraformWrapper.extraRuntimeInputs = [ inputs'.clan-core.packages.default ];
            terraformWrapper.prefixText = ''
              TF_VAR_passphrase=$(clan secrets get tf-passphrase)
              export TF_VAR_passphrase
              TF_ENCRYPTION=$(cat <<'EOF'
              key_provider "pbkdf2" "state_encryption_password" {
                passphrase = var.passphrase
              }
              method "aes_gcm" "encryption_method" {
                keys = key_provider.pbkdf2.state_encryption_password
              }
              state {
                enforced = true
                method = method.aes_gcm.encryption_method
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
