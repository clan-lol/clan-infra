{
  _class,
  self,
  config,
  lib,
  pkgs,
  ...
}:
{
  # Users are only managed if they're present in `users.knownUsers`
  imports = lib.optional (_class == "darwin") {
    users.knownUsers = lib.attrNames (
      lib.filterAttrs (name: value: value.isNormalUser) config.users.users
    );
  };

  options = {
    users.startingUid = lib.mkOption {
      internal = true;
      type = lib.types.ints.positive;
      default = if _class == "darwin" then 550 else 1000;
      description = ''
        Exclusive to this repo

        We don't want to start at UID 1000 on macOS, see: https://apple.stackexchange.com/a/434712
      '';
    };

    users.users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }@args:
          {
            imports = lib.optional (_class == "darwin") {
              options.isNormalUser = lib.mkOption {
                internal = true;
                type = lib.types.bool;
                default = false;
                description = ''
                  nix-darwin currently doesn't have this option so let's create it for now :)
                '';
              };

              config = lib.mkIf args.config.isNormalUser {
                createHome = lib.mkDefault true;
                home = lib.mkDefault "/Users/${name}";
              };
            };

            options.gitea.username = lib.mkOption {
              type = lib.types.str;
              default = name;
              description = ''
                Add the user's Gitea username so that they can have admin access on Buildbot as well.

                This is case sensitive and defaults to their Linux username.
              '';
            };
          }
        )
      );
    };
  };

  config = {
    users.users =
      let
        # GID 80 = admin, nix-darwin doesn't support extraGroups currently
        grantSudoAccess = if _class == "darwin" then { gid = 80; } else { extraGroups = [ "wheel" ]; };
        uid = offset: config.users.startingUid + offset;
      in
      {
        # If you want to do remote builds, use this account as it has no sudo and is not trusted
        # you will need to use `ssh-ng://` to be able to build trustless input-addressed derivations
        builder = {
          isNormalUser = true;
          home = "/var/lib/builder";
          shell = pkgs.zsh;
          uid = uid 50;
          openssh.authorizedKeys.keys =
            (builtins.attrValues {
              web01 =
                self.nixosConfigurations.web01.config.clan.core.vars.generators.openssh.files."ssh.id_ed25519.pub".value;
              enzime = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHYKiMQTkDFdiZJIKQhyqLms4rcUfDw8FCY/vju38lfd";
            })
            ++ config.users.users.root.openssh.authorizedKeys.keys;
        } // (if _class == "darwin" then { } else { group = "builder"; });
        mic92 = {
          isNormalUser = true;
          shell = pkgs.zsh;
          uid = uid 0;
          openssh.authorizedKeys.keys = [
            "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLMlGNda7bilB0+3aMeJSFcB17auBPV0WhW60WlGZsQRF50Z/OgIHAA0/8HaxPmpIOLHv8JO3dCsj+OY1iS4FNo= joerg@turingmachine"
            "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCsjXKHCkpQT4LhWIdT0vDM/E/3tw/4KHTQcdJhyqPSH0FnwC8mfP2N9oHYFa2isw538kArd5ZMo5DD1ujL5dLk= ssh@secretive.Joerg’s-Laptop.local"
          ];
          gitea.username = "Mic92";
        } // grantSudoAccess;
        lassulus = {
          isNormalUser = true;
          shell = pkgs.zsh;
          uid = uid 1;
          openssh.authorizedKeys.keys = [
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIb3uuMqE/xSJ7WL/XpJ6QOj4aSmh0Ga+GtmJl3CDvljGuIeGCKh7YAoqZAi051k5j6ZWowDrcWYHIOU+h0eZCesgCf+CvunlXeUz6XShVMjyZo87f2JPs2Hpb+u/ieLx4wGQvo/Zw89pOly/vqpaX9ZwyIR+U81IAVrHIhqmrTitp+2FwggtaY4FtD6WIyf1hPtrrDecX8iDhnHHuGhATr8etMLwdwQ2kIBx5BBgCoiuW7wXnLUBBVYeO3II957XP/yU82c+DjSVJtejODmRAM/3rk+B7pdF5ShRVVFyB6JJR+Qd1g8iSH+2QXLUy3NM2LN5u5p2oTjUOzoEPWZo7lykZzmIWd/5hjTW9YiHC+A8xsCxQqs87D9HK9hLA6udZ6CGkq4hG/6wFwNjSMnv30IcHZzx6IBihNGbrisrJhLxEiKWpMKYgeemhIirefXA6UxVfiwHg3gJ8BlEBsj0tl/HVARifR2y336YINEn8AsHGhwrPTBFOnBTmfA/VnP1NlWHzXCfVimP6YVvdoGCCnAwvFuJ+ZuxmZ3UzBb2TenZZOzwzV0sUzZk0D1CaSBFJUU3oZNOkDIM6z5lIZgzsyKwb38S8Vs3HYE+Dqpkfsl4yeU5ldc6DwrlVwuSIa4vVus4eWD3gDGFrx98yaqOx17pc4CC9KXk/2TjtJY5xmQ=="
          ];
        } // grantSudoAccess;
        dave = {
          isNormalUser = true;
          shell = "/run/current-system/sw/bin/fish";
          uid = uid 2;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDuhpzDHBPvn8nv8RH1MRomDOaXyP4GziQm7r3MZ1Syk"
          ];
          gitea.username = "DavHau";
        } // grantSudoAccess;
        qubasa = {
          isNormalUser = true;
          shell = pkgs.zsh;
          uid = uid 3;
          openssh.authorizedKeys.keys = [
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDB0d0JA20Vqn7I4lCte6Ne2EOmLZyMJyS9yIKJYXNLjbLwkQ4AYoQKantPBkTxR75M09E7d3j5heuWnCjWH45TrfQfe1EOSSC3ppCI6C6aIVlaNs+KhAYZS0m2Y8WkKn+TT5JLEa8yybYVN/RlZPOilpj/1QgjU6CQK+eJ1k/kK+QFXcwN82GDVh5kbTVcKUNp2tiyxFA+z9LY0xFDg/JHif2ROpjJVLQBJ+YPuOXZN5LDnVcuyLWKThjxy5srQ8iDjoxBg7dwLHjby5Mv41K4W61Gq6xM53gDEgfXk4cQhJnmx7jA/pUnsn2ZQDeww3hcc7vRf8soogXXz2KC9maiq0M/svaATsa9Ul4hrKnqPZP9Q8ScSEAUX+VI+x54iWrnW0p/yqBiRAzwsczdPzaQroUFTBxrq8R/n5TFdSHRMX7fYNOeVMjhfNca/gtfw9dYBVquCvuqUuFiRc0I7yK44rrMjjVQRcAbw6F8O7+04qWCmaJ8MPlmApwu2c05VMv9hiJo5p6PnzterRSLCqF6rIdhSnuOwrUIt1s/V+EEZXHCwSaNLaQJnYL0H9YjaIuGz4c8kVzxw4c0B6nl+hqW5y5/B2cuHiumnlRIDKOIzlv8ufhh21iN7QpIsPizahPezGoT1XqvzeXfH4qryo8O4yTN/PWoA+f7o9POU7L6hQ=="
          ];
          gitea.username = "Qubasa";
        } // grantSudoAccess;
        kenji = {
          isNormalUser = true;
          shell = pkgs.zsh;
          uid = uid 4;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJXGRXiq61BQBUkQLBn720pzxiAZqchHWm504gWa2rE2"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOu1koO8pJ6t0I+rpSVfjD1m6eDk9KTp8cvGL500tsQ9"
          ];
        } // grantSudoAccess;
        johannes = {
          isNormalUser = true;
          shell = pkgs.zsh;
          uid = uid 5;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGLuev3+8kF+pd1YnCRR7Kw9i9DswOMvGhvdQq6dEIJF"
          ];
          gitea.username = "hsjobeki";
        } // grantSudoAccess;
        timo = {
          isNormalUser = true;
          shell = pkgs.zsh;
          uid = uid 7;
          openssh.authorizedKeys.keys = [
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDyCKP5KDMkOOHTiWf1q6HD/jXlpOQSMvs9r6eYxUgazn6dMA5nUd0jzm5elTdEybpT0ftfiNqwWREZ5un4xX+Ibz8xVNiL0IRo6h5cFGfJvBljTrAXjEXY3DT12KFsBFrh6b/GfPVeWdhMNNZLayyJ6rZ3Nb0cNjUNT9N6NCyrYou3OIFwud8lSHCp/daZJcRELetULV/pPxJMNiWzNxTEdiiLlt445eNpHqq05Q7Uf9nX/DwFerd/Mwz+BfWN9hKOns9VWmKZ7A4tOXB6gXK+WKSeWU5vDXwYYKL5MMqG6MWQiJS+Y9u81EK0KQiukxWESOUOeLMBBBx8c38sWjHXGpQVpgl4ZN6zemGcD6P3d+2G+NLW9oOxxP4BDHw2MJjpkopRBKZh09tFggxUh5mZjLYc/LVGgz/vBzbFLbbXx3zPC/C2t+Ft4Dx9yLD82wf3y1EbvWG4CQc1jZNx/MTzCYSVnzIPAiuxtuPSgwaZGPmxYtEpvHbBzQ7Ec30+aQ0="
          ];
        } // grantSudoAccess;
        enzime = {
          isNormalUser = true;
          shell = pkgs.zsh;
          uid = uid 8;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKZfejb9htpSB5K9p0RuEowErkba2BMKaze93ZVkQIE"
          ];
          gitea.username = "Enzime";
        } // grantSudoAccess;
        pinpox = {
          isNormalUser = true;
          shell = pkgs.zsh;
          uid = uid 9;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSJJs01RqXS6YE5Jf8LUJoJVBxFev3R18FWXJyLeYJE"
          ];
        } // grantSudoAccess;
        berwn = {
          # Alex - Chiang Mai
          isNormalUser = true;
          shell = pkgs.bash;
          uid = uid 10;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAB/raxJR8gASmquP63weHelbi+da2WBJR1DgzHPNz/f"
          ];
          gitea.username = "berwn";
        } // grantSudoAccess;
        kurogeek = {
          isNormalUser = true;
          shell = pkgs.zsh;
          uid = uid 11;
          openssh.authorizedKeys.keys = [
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9vyls+5iD4OxxbG+nzZ/e+AEc1nZPBkPQz7Sfl3xoFmBUm8av288Lf3QtjeKr9ItqHOfAuEO6ZBIePDzdQpHoRA29iQw3+RGqv82N3nEagnb+R71Daj+6G4VGKg8wwMd5csDAv+htBxxSfULnuJ+o7j9VxVgwl8J5hQ4uKK1BeXDopM4bCxTNhkIAAuwHfjcFs5J0jdgKwmZwukXc53EhYj2/eMhARy5LwJhNOy9Rq+1hVLO0KnT4imY8I4FIT441b88Ae3Etn1w/zL3BASvTBzXR/FYgbBXpbm91dtpW7p+fRw7hZFAuAl172qgLMEY4Q+nF428NURlHYARLXlp1OdLuXgnJhKspgVc9k2h42j8Vc5+nHdZMCdyEhUgTNpTE+lNspM6F0b/Ee15oMk782UAAZH7hU8Abm0Z3MKz04HMZ5/8oq2RbkgObExcoB7Z9gEr+BVDiSqU9PLd+iLJeTjJiTcnRWkUNkHTU9ZkqUgxkE5q0SJsTFe9c3OXESoE= panupong
"
          ];
          gitea.username = "kurogeek";
        } // grantSudoAccess;
        daniel = {
          isNormalUser = true;
          shell = "/run/current-system/sw/bin/bash";
          uid = uid 13;
          openssh.authorizedKeys.keys = [
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDiAbxcyiQzOiASAVP1WusoImiknbNeJYI6oW1mqXoU8NbxcV1qenLa/IrjO27ebNrxQUt9JDliW4xuFjyxM7kJNv94zGgb/es1wEMlR4PS6Pgd1ZIL4BNpjIwpZF2q/nQ+IUZgUnav546M6y6pQW9YB+GpecXiBn/Vqx4YM4eBN7102wRS3TH1bQVhug1NCsp6xPyJ6edvTO7iqxRR63AAO7FIj5phPeHhFb4ZYhAz6mYpUGEfE41J7UPVy/zq4UzqMYj8yRcyhUEe5/3d27LtALQ43p8oWPIG6isJhYXSiXwBkEpMI5+dfFKfWo7S/2Z41jdEtoBhGOqvI4sbzlvI0Zhr4BI/XbBP+5D0zS2j0iE3y9WiBJDMZ1I1h/DmvH4pbaPd+79N6hWgiGOs1PmhsaTxK6lGI7ro4n5Z85Caj6h6UP+qWsGO2HromkAFtlexgJw49qk2QjID8IXLTU7Um+5fpbLi8xF5j0+EtzC+v5898ixIMZS/qjjr9yZP0Z4ZKfCM4mrQLrqmkHis8GQ0lRzcKqpZNeAAIPvEvDCO+uk21MV/+XvJaticG2FZjaKk0UphlZXkUnQVF28nICdxJPStG+w5Qo09rB3q2GQtBPpd5QdzWU8l/WYfh9p497vxOsVfBS4eTd8KQXQS1+QWpIEi4zEGpjAH0HEeL83lrQ== skunklab@MACBOOK-PRO.local"
          ];
        };

        root.openssh.authorizedKeys.keys = builtins.concatMap (user: user.openssh.authorizedKeys.keys) (
          builtins.attrValues (
            lib.filterAttrs (
              _name: value:
              value.isNormalUser
              && (if _class == "darwin" then value.gid == 80 else builtins.elem "wheel" value.extraGroups)
            ) config.users.users
          )
        );
      };

    programs.zsh.enable = true;
    security.sudo = lib.optionalAttrs (_class == "nixos") {
      wheelNeedsPassword = false;
    };

    users.groups.builder = { };

    nix.settings.trusted-public-keys = [
      self.nixosConfigurations.web01.config.clan.core.vars.generators.nix-signing-key.files."key.pub".value
    ];
  };
}
