# clan-infra

This repository contains nixos modules and terraform code that powers clan.lol.
The website and git hosting is currently on [hetzner](https://www.hetzner.com/).

## Servers
- web01:
  - Instance type: [ex101](https://www.hetzner.com/de/dedicated-rootserver/ex101)
  - CPU: Intel Core i9-13900 (24 cores / 32 threads)
  - RAM: 64GB DDR5
  - Drives: 2 x 1.92 TB NVME

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
