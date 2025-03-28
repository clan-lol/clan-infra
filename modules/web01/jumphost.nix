{ config, lib, ... }:
{
  imports = [
    ../ssh-keys.nix
  ];
  users.users.tunnel = {
    isNormalUser = true;
    home = "/var/empty";
    shell = "/run/current-system/sw/bin/nologin";
    openssh.authorizedKeys.keys = builtins.concatLists (
      lib.mapAttrsToList (_: user: user.openssh.authorizedKeys.keys) (
        lib.filterAttrs (name: user: user.isNormalUser && name != "tunnel") config.users.users
      )
      ++ (lib.attrValues config.users.ssh-keys)
    );
  };

  services.openssh = {
    # Increase number of connections for deployment scripts
    settings.MaxStartups = "64:30:256";
    extraConfig = ''
      Match User tunnel
        AllowTcpForwarding yes
        X11Forwarding no
        AllowAgentForwarding no
        PermitTunnel no
        PermitTTY no
        PasswordAuthentication no
    '';
  };

  networking.firewall.allowedTCPPorts = [ 22 ];
}
