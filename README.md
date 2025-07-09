# clan-infra

This repository contains nixos modules and terraform code that powers
[clan.lol](https://clan.lol/). The website and git are currently hosted on
[Hetzner](https://www.hetzner.com/). The demo server and Jitsi server are hosted
on [Vultr](https://www.vultr.com/).

## Adding a New Admin User

To add a new admin user, follow these steps:

1. **User generates an age key:**

The new user runs:

```
$ clan secrets key generate
```

This creates an age key pair, which is used for secret management.

2. **User provides credentials to an existing admin:**

The user shares **both** of the following with a current admin:

- Their **SSH public key**
- Their **age public key** (found in `~/.config/sops/age/keys.txt` or
  `~/Library/Application Support/sops/age/keys.txt` on macOS)

3. **Admin adds the user:**

The admin runs:

```
$ clan secrets users add <username> <age-key>
$ clan secrets groups add-user admins <username>
```

Replace `<username>` and `<age-key>` with the actual values.

4. **Admin updates configuration:**

Add the new user to the [`modules/admins.nix`](modules/admins.nix) file.

The new admin user will now have access according to the configuration.

## Joining the clan-infra Zerotier Network

To connect your device to the clan-infra Zerotier network:

1. **Get the Zerotier network ID:**

On any existing machine (e.g., `web01`), run:

```bash
clan vars list web01
```

Look for the line:

```
zerotier/zerotier-network-id: a9b4872919354736
```

2. **Configure your device to join the network:**

Add the following to your NixOS configuration:

```nix
services.zerotierone.joinNetworks = [
  "a9b4872919354736" # clan-infra network
];
```

3. **Find your device's Zerotier ID:**

After starting Zerotier, run:

```bash
sudo zerotier-cli info
```

The output will look like:

```
200 info <myid> 1.14.2 ONLINE
```

Note your `<myid>`.

4. **Authorize your device on the network:**

SSH into `web01` (or another admin machine) and run:

```bash
sudo zerotier-members allow <myid>
```

Once authorized, your device will be connected to the clan-infra Zerotier
network.

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

## web02

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
$ clan machines update web02
```

### Redeploy server

To redeploy the server without running `terraform destroy` which will take down
the `clan.lol` DNS:

```
# Run `apply` script first to ensure `terraform init` gets run
$ nix run clan-infra#terraform
$ nix run clan-infra#terraform.terraform -- apply -replace "vultr_instance.web02"
```

### Destroy server

To destroy just the server without taking down the `clan.lol` DNS:

```
# Run `apply` script first to ensure `terraform init` gets run
$ nix run clan-infra#terraform
$ nix run clan-infra#terraform.terraform -- destroy -target "vultr_instance.web02"
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

To access this machine, you'll need to add this to your SSH config:

```nix
{
  programs.ssh.extraConfig = ''
    Host build01
      ProxyJump tunnel@clan.lol
      Hostname build01.vpn.clan.lol
  '';
}
```

```
$ clan machines update build01
```

## build-x86-01

- Instance type: Hetzner dedicated server (AMD)
- Platform: x86_64-linux
- Max parallel jobs: 32
- Features: big-parallel, kvm, nixos-test, uid-range, recursive-nix

### Initial setup

To install the system, you can run the following command:

```
$ clan machines install build-x86-01 --update-hardware-config nixos-facter --no-reboot
```

### Deploy new configuration

```
$ clan machines update build-x86-01
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

3. Clone this repo into a temporary directory

```
nix run nixpkgs#git -- clone https://git.clan.lol/clan/clan-infra.git temp-bootstrap
```

4. Install nix-darwin from the temporary directory

```
nix run nix-darwin -- switch --flake ./temp-bootsrap
```

5. Log in to Tailscale

```
sudo tailscale up
```

6. Enable `Allow full disk access for remote users` and
   `Allow access for all users` in
   `System Settings > General > Sharing > Remote Login`

7. Delete the temporary directory

```
rm -rf ./temp-bootstrap
```

### Deploy new configuration

To access this machine, you'll need to add this to your SSH config:

```nix
{
  programs.ssh.extraConfig = ''
    Host build02
      ProxyJump <clanuser>@clan.lol
      Hostname build02.vpn.clan.lol
  '';
}
```

```
$ clan machines update build02
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

Currently DNS can't be updated separately to the machines, so you'll need to
deploy the entire Terraform configuration:

```
$ nix run clan-infra#terraform
```

## storinator01

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
{
  programs.ssh.extraConfig = ''
    Host storinator01
      ProxyJump <clan-user>@clan.lol
      Hostname storinator01.vpn.clan.lol
  '';
}
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
