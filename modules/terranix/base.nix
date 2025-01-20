{ lib, ... }:

{
  variable.passphrase = { };

  terraform.encryption.key_provider.pbkdf2.state_encryption_password = {
    passphrase = lib.tf.ref "var.passphrase";
  };

  terraform.encryption.method.aes_gcm.encryption_method.keys =
    lib.tf.ref "key_provider.pbkdf2.state_encryption_password";

  terraform.encryption.state.enforced = true;
  terraform.encryption.state.method = lib.tf.ref "method.aes_gcm.encryption_method";
}
