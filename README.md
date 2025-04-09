# clan-infra

This repository contains nixos modules and terraform code that powers
[clan.lol](https://clan.lol/). The website and git are currently hosted on
[Hetzner](https://www.hetzner.com/). The demo server and Jitsi server are hosted
on [Vultr](https://www.vultr.com/).

## web01

- Instance type: [ax162-r](https://www.hetzner.com/dedicated-rootserver/ax162-r)
- CPU: AMD EPYC™ 9454P
- RAM: 256 GB DDR5 ECC
- Storage: 2 x 1.92 TB NVMe

### Initial setup

To install the system, you can run the following command:

```
$ clan machines install web01 --update-hardware-config nixos-facter --no-reboot
```

Then you can run the following script to reboot the machine and unlock the
encrypted root filesystem:

```
$ ./machines/web01/reboot.sh
```

### Deploy new configuration

```
$ clan machines update web01
```

## jitsi01

- Instance type: [vc2-2c-4gb](https://www.vultr.com/pricing/#cloud-compute)
- CPU: 2 Intel vCPU cores
- RAM: 4 GB
- Storage: 80 GB SSD

### Initial setup

```
$ nix run clan-infra#terraform
```

### Deploy new configuration

```
$ clan machines update jitsi01
```

### Redeploy server

To redeploy the server without running `terraform destroy` which will take down
the `clan.lol` DNS:

```
# Run `apply` script first to ensure `terraform init` gets run
$ nix run clan-infra#terraform
$ nix run clan-infra#terraform.terraform -- apply -replace "vultr_instance.jitsi01"
```

### Destroy server

To destroy just the server without taking down the `clan.lol` DNS:

```
# Run `apply` script first to ensure `terraform init` gets run
$ nix run clan-infra#terraform
$ nix run clan-infra#terraform.terraform -- destroy -target "vultr_instance.jitsi01"
```

## demo01

- Instance type: [vc2-2c-4gb](https://www.vultr.com/pricing/#cloud-compute)
- CPU: 2 Intel vCPU cores
- RAM: 4 GB
- Storage: 80 GB SSD

### Initial setup

```
$ nix run clan-infra#terraform
```

### Deploy new configuration

```
$ clan machines update demo01
```

### Redeploy server

To redeploy the server without running `terraform destroy` which will take down
the `clan.lol` DNS:

```
# Run `apply` script first to ensure `terraform init` gets run
$ nix run clan-infra#terraform
$ nix run clan-infra#terraform.terraform -- apply -replace "vultr_instance.demo01"
```

### Destroy server

To destroy just the server without taking down the `clan.lol` DNS:

```
# Run `apply` script first to ensure `terraform init` gets run
$ nix run clan-infra#terraform
$ nix run clan-infra#terraform.terraform -- destroy -target "vultr_instance.demo01"
```

## build01

- Instance type: [rx170](https://www.hetzner.com/dedicated-rootserver/rx170)
- CPU: Ampere® Altra® Q80-30
- RAM: 128 GB DDR4 ECC
- Storage: 2 x 960 GB NVMe

### Initial setup

To install the system, you can run the following command:

```
$ nix run clan-infra#terraform
```

### Deploy new configuration

```
$ clan machines update build01
```

## build02

- Instance type:
  [Apple Mac mini (2024) (Mac16,10)](https://everymac.com/systems/apple/mac_mini/specs/mac-mini-m4-10-core-cpu-10-core-gpu-2024-specs.html)
- CPU: Apple M4 chip with 10-core CPU, 10-core GPU, 16-core Neural Engine
- RAM: 24 GB unified memory
- Storage: 512 GB SSD

### Initial setup

1. Install Nix using the Nix installer from Determinate Systems

```
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install --diagnostic-endpoint=""
```

2. Enable `Screen Sharing` in `System Settings > General > Sharing`

You can leave both `Anyone may request permission to control screen` and
`VNC viewers may control screen with password` disabled as macOS will allow you
to control the screen by connecting with your macOS username and password.

3. Clone this repo

```
nix run nixpkgs#git -- clone https://git.clan.lol/clan/clan-infra.git ~/.config/nix-darwin
```

4. Install nix-darwin

```
nix run nix-darwin -- switch --flake ~/.config/nix-darwin
```

5. Log in to Tailscale

```
sudo tailscale up
```

6. Enable `Allow full disk access for remote users` and
   `Allow access for all users` in
   `System Settings > General > Sharing > Remote Login`

### Deploy new configuration

To access this machine, you'll need to add this to your SSH config:

```nix
programs.ssh.extraConfig = ''
  Host build02
    ProxyJump tunnel@clan.lol
    Hostname 100.98.54.8
'';
```

Due to quirks in nix-darwin, deployment must be done from `admin` and not any
other users. The easiest way to do this is by running the `deploy-build02`
package which will deploy the specified flake:

```
$ nix run clan-infra#deploy-build02
```

The deployment script also supports overriding inputs:

```
nix run clan-infra#deploy-build02 -- --override-input nixpkgs ~/nixpkgs
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

Currently DNS can't be updated separately to `jitsi01`

```
$ nix run clan-infra#terraform
```

## Storinator01

- Instance type:
  [Storinator Q30](https://www.45drives.com/products/storinator-q30-configurations.php)
- CPU: Intel Xeon Silver 4216 (16C/32T)
- RAM: 128 GB DDR5 ECC
- Storage:
  - OS: 2 x 500GB SATA SSD
  - Data: 18 HDDs in zraid2 + 1 Spare == 200TB

### Deploy new configuration

To access this machine, you'll need to add this to your SSH config:

```nix
programs.ssh.extraConfig = ''
  Host storinator01
    ProxyJump tunnel@clan.lol
    Hostname fda9:b487:2919:3547:3699:9393:7f57:6e6b
'';
```

```
$ clan machines update storinator01
```

## Adding a new machine

1. Copy an existing machine
2. Run `clan vars generate <machine>`
3. If you aren't using Terraform to provision the server, make sure to add the
   Terraform deployment SSH key to your server which you can find by running:

```
$ nix run clan-infra#terraform.terraform -- init
$ nix run clan-infra#terraform.terraform -- state show tls_private_key.ssh_deploy_key
```

4. `nix run clan-infra#terraform` to run the initial deploy

## To add a new project to CI

1. Add the 'buildbot-clan' topic to the repository using the "Manage topics"
   button below the project description
2. Go to https://buildbot.clan.lol/#/builders/2 and press "Update projects"
   after you have logged in.
