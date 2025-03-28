{ lib, ... }:
{
  options = {
    users.ssh-keys = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {
        matthew = [
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOJDRQfb1+7VK5tOe8W40iryfBWYRO6Uf1r2viDjmsJtAAAABHNzaDo= backup-yubikey"
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIDgsWq+G/tcr6eUQYT7+sJeBtRmOMabgFiIgIV44XNc6AAAABHNzaDo= main-yubikey"
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJMi3TAuwDtIeO4MsORlBZ31HzaV5bji1fFBPcC9/tWuAAAABHNzaDo= nano-yubikey"
        ];
        w = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINpWOqoN29X9v/2NisR2yFaazGLsEvG6oE+VLlOOIrxB w-main" ];
        vi = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAmgyEGuY/r7SDlJgrzYmQqpcWS5W+fCzRi3OS59ne4W openpgp:0xFF687387"
        ];
      };
    };
  };
}
