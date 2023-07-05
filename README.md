# clan-infra

This repository contains nixos modules and terraform code that powers clan.lol.
The website and git hosting is currently on [hetzner](https://www.hetzner.com/).

## Servers

- web01:
  - Instance type: CPX42
  - CPU: 8 vCPUs on AMD
  - RAM: 16GB
  - Drives: 80GB SSD

## To deploy new ssh keys on hcloud:

```
$ cd ./targets/admins
$ ./tf.sh apply
```

## To deploy a server i.e. web01:

```
$ cd ./targets/web01
$ ./tf.sh apply
```

## To update the website

```
$ cd ./targets/web01
$ nix flake lock --update-input homepage --commit-lock-file
$ ./tf.sh apply
```