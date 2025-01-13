{ config, ... }:

{
  resource.hcloud_ssh_key.enzime = {
    name = "enzime";
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKZfejb9htpSB5K9p0RuEowErkba2BMKaze93ZVkQIE";
  };

  resource.hcloud_server.jitsi01 = {
    name = "jitsi01";
    image = "debian-12";
    server_type = "cpx21";
    location = "sin";
    ssh_keys = [ (config.resource.hcloud_ssh_key.enzime "id") ];
    shutdown_before_deletion = true;
    backups = false;
  };

  resource.null_resource.nixos-remote = {
    triggers = {
      instance_id = null;
    };
    provisioner.local-exec = {
      command = "clan machines install jitsi01 --target-host root@${config.resource.hcloud_server.jitsi01 "ipv4_address"} --yes";
    };
  };
}
