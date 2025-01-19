{
  config,
  pkgs,
  lib,
  ...
}:

{
  variable.passphrase = { };

  terraform.encryption.key_provider.pbkdf2.state_encryption_password = {
    passphrase = lib.tf.ref "var.passphrase";
  };

  terraform.encryption.method.aes_gcm.encryption_method.keys =
    lib.tf.ref "key_provider.pbkdf2.state_encryption_password";

  terraform.encryption.state.enforced = true;
  terraform.encryption.state.method = lib.tf.ref "method.aes_gcm.encryption_method";

  terraform.required_providers.external.source = "hashicorp/external";
  terraform.required_providers.hetznerdns.source = "timohirt/hetznerdns";
  terraform.required_providers.local.source = "hashicorp/local";
  terraform.required_providers.tls.source = "hashicorp/tls";
  terraform.required_providers.vultr.source = "vultr/vultr";

  data.external.hetznerdns-token = {
    program = [
      (lib.getExe (
        pkgs.writeShellApplication {
          name = "get-clan-secret";
          text = ''
            jq -n --arg secret "$(clan secrets get hetznerdns-token)" '{"secret":$secret}'
          '';
        }
      ))
    ];
  };

  data.external.vultr-api-key = {
    program = [
      (lib.getExe (
        pkgs.writeShellApplication {
          name = "get-clan-secret";
          text = ''
            jq -n --arg secret "$(clan secrets get vultr-api-key)" '{"secret":$secret}'
          '';
        }
      ))
    ];
  };

  provider.hetznerdns.apitoken = config.data.external.hetznerdns-token "result.secret";
  provider.vultr.api_key = config.data.external.vultr-api-key "result.secret";
}
