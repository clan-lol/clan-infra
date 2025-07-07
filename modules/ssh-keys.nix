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
        kurogeek = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9vyls+5iD4OxxbG+nzZ/e+AEc1nZPBkPQz7Sfl3xoFmBUm8av288Lf3QtjeKr9ItqHOfAuEO6ZBIePDzdQpHoRA29iQw3+RGqv82N3nEagnb+R71Daj+6G4VGKg8wwMd5csDAv+htBxxSfULnuJ+o7j9VxVgwl8J5hQ4uKK1BeXDopM4bCxTNhkIAAuwHfjcFs5J0jdgKwmZwukXc53EhYj2/eMhARy5LwJhNOy9Rq+1hVLO0KnT4imY8I4FIT441b88Ae3Etn1w/zL3BASvTBzXR/FYgbBXpbm91dtpW7p+fRw7hZFAuAl172qgLMEY4Q+nF428NURlHYARLXlp1OdLuXgnJhKspgVc9k2h42j8Vc5+nHdZMCdyEhUgTNpTE+lNspM6F0b/Ee15oMk782UAAZH7hU8Abm0Z3MKz04HMZ5/8oq2RbkgObExcoB7Z9gEr+BVDiSqU9PLd+iLJeTjJiTcnRWkUNkHTU9ZkqUgxkE5q0SJsTFe9c3OXESoE= panupong
"
        ];
        qubasa = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDB0d0JA20Vqn7I4lCte6Ne2EOmLZyMJyS9yIKJYXNLjbLwkQ4AYoQKantPBkTxR75M09E7d3j5heuWnCjWH45TrfQfe1EOSSC3ppCI6C6aIVlaNs+KhAYZS0m2Y8WkKn+TT5JLEa8yybYVN/RlZPOilpj/1QgjU6CQK+eJ1k/kK+QFXcwN82GDVh5kbTVcKUNp2tiyxFA+z9LY0xFDg/JHif2ROpjJVLQBJ+YPuOXZN5LDnVcuyLWKThjxy5srQ8iDjoxBg7dwLHjby5Mv41K4W61Gq6xM53gDEgfXk4cQhJnmx7jA/pUnsn2ZQDeww3hcc7vRf8soogXXz2KC9maiq0M/svaATsa9Ul4hrKnqPZP9Q8ScSEAUX+VI+x54iWrnW0p/yqBiRAzwsczdPzaQroUFTBxrq8R/n5TFdSHRMX7fYNOeVMjhfNca/gtfw9dYBVquCvuqUuFiRc0I7yK44rrMjjVQRcAbw6F8O7+04qWCmaJ8MPlmApwu2c05VMv9hiJo5p6PnzterRSLCqF6rIdhSnuOwrUIt1s/V+EEZXHCwSaNLaQJnYL0H9YjaIuGz4c8kVzxw4c0B6nl+hqW5y5/B2cuHiumnlRIDKOIzlv8ufhh21iN7QpIsPizahPezGoT1XqvzeXfH4qryo8O4yTN/PWoA+f7o9POU7L6hQ== lhebendanz@nixos
"
        ];
      };
    };
  };
}
