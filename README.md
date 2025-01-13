# clan-infra

This repository contains nixos modules and terraform code that powers
[clan.lol](https://clan.lol/). The website, git and Jitsi are currently hosted
on [Hetzner](https://www.hetzner.com/).

## Servers

## web01

- Instance type: [ax162-r](https://www.hetzner.com/dedicated-rootserver/ax162-r)
- CPU: AMD EPYC™ 9454P
- RAM: 256 GB DDR5 ECC
- Drives: 2 x 1.92 TB NVME

### Initial setup

To install the system, you can run the following command:

```
$ clan machines install web01 --update-hardware-config nixos-facter --no-reboot
```

Then you can run the following script to reboot the machine and unlock the
encrypted root filesystem:

```
$ ./targets/web01/reboot.sh
```

### Deploy new configuration

```
$ clan machines update web01
```

## jitsi01

- Instance type: [cpx21](https://www.hetzner.com/cloud/)
- CPU: 3 AMD vCPU cores
- RAM: 4 GB
- SSD: 80 GB

### Initial setup

```
$ nix run clan-infra#jitsi01
```

### Deploy new configuration

```
$ clan machines update jitsi01
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
