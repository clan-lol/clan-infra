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

  terraform.required_providers.hcloud.source = "hetznercloud/hcloud";
  terraform.required_providers.external.source = "hashicorp/external";
  terraform.required_providers.local.source = "hashicorp/local";

  data.external.hcloud-api-key = {
    program = [
      (lib.getExe (
        pkgs.writeShellApplication {
          name = "get-clan-secret";
          text = ''
            jq -n --arg secret "$(clan secrets get hcloud-api-key)" '{"secret":$secret}'
          '';
        }
      ))
    ];
  };

  provider.hcloud.token = config.data.external.hcloud-api-key "result.secret";
}
