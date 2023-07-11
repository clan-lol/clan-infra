{ lib, ... }:
{
  networking.firewall.allowedTCPPorts = [ 9993 ];
  networking.firewall.allowedUDPPorts = [ 9993 ];
  networking.firewall.interfaces."zt+".allowedTCPPorts = [ 5353 ];
  networking.firewall.interfaces."zt+".allowedUDPPorts = [ 5353 ];

  # Note avahi was super slow. systemd-resolved worked much faster for mdns
  systemd.network.networks.zerotier = {
    matchConfig.Name = "zt*";
    networkConfig = {
      LLMNR = true;
      LLDP = true;
      MulticastDNS = true;
      KeepConfiguration = "static";
    };
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
