{ lib, ... }:
{
  networking.firewall.allowedTCPPorts = [
    9993 
    # FIXME: figure out why it's not enough to just allow it on interface zt*
    5353
  ];
  networking.firewall.allowedUDPPorts = [
    9993
    5353
  ];
  systemd.network.networks = {
    zerotier.extraConfig = ''
      [Match]
      Name=zt*

      [Network]
      LLMNR=true
      LLDP=true
      MulticastDNS=true
      KeepConfiguration=static
    '';
  };

  services.zerotierone = {
    enable = true;
    joinNetworks = [
      "33d87fa6bd93423e"
    ];
  };
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "zerotierone"
  ];
}
