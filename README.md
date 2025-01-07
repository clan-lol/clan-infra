# clan-infra

This repository contains nixos modules and terraform code that powers clan.lol.
The website and git hosting is currently on [hetzner](https://www.hetzner.com/).

## Servers

- web01:
  - Instance type:
    [ex101](https://www.hetzner.com/de/dedicated-rootserver/ex101)
  - CPU: Intel Core i9-13900 (24 cores / 32 threads)
  - RAM: 64GB DDR5
  - Drives: 2 x 1.92 TB NVME

## Install a new server

To install the system, you can run the following command:

```
$ clan machines install <host> --update-hardware-config nixos-facter --no-reboot
```

Then you can run the following script to reboot the machine and unlock the
encrypted root filesystem:

```
$ ./targets/web01/reboot.sh
```

## To deploy a server i.e. web01:

```
$ clan machines update
```

## Adding new users

Add them to the [configuration](modules/admins.nix).

The user can create an age key:

```
$ clan secrets key generate
```

The private key (identity in age terms) and public key (recipient in age terms)
are stored in `~/.config/sops/age/keys.txt`
(`~/Library/Application Support/sops/age/keys.txt` on macOS).

Add the new user's age key:

```
$ clan secrets users add <user> <age-key>
```

Add the new user as an admin:

```
$ clan secrets groups add-user admins <user>
```

## Update DNS

```
$ cd ./targets/web01
$ ./tf.sh apply
```

## To add a new project to CI

1. Add the 'buildbot-clan' topic to the repository using the "Manage topics"
   button below the project description
2. Go to https://buildbot.clan.lol/#/builders/2 and press "Update projects"
   after you have logged in.
