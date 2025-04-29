{ config, pkgs, ... }:
{
  virtualisation.libvirtd.enable = true;

  users.users."kvm" = {
    openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
    isNormalUser = true;
    group = "kvm";
    extraGroups = [ "libvirtd" ];
    packages = with pkgs; [
      cdrtools
    ];
  };
  users.groups.kvm = { };

}
