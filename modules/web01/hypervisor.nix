{ config, pkgs, ... }:
{
  virtualisation.libvirtd.enable = true;

  users.users."kvm" = {
    openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys ++
    [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIODEh8Fy5YnMRepnnv4ZnRtHkZIzo0b1rdQ3STBHHBvd kvm@clan.lol
"
    ];
    isNormalUser = true;
    group = "kvm";
    extraGroups = [ "libvirtd" ];
    packages = with pkgs; [
      cdrtools
    ];
  };
  users.groups.kvm = { };

}
