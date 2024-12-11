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

## To deploy a server i.e. web01:

```
$ clan machines update
```

## Adding new users

Add them in the [configuration](modules/admins.nix).

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
