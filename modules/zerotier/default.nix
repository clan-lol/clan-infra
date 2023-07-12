{ lib, pkgs, ... }:
{
  networking.firewall.allowedTCPPorts = [
    9993
    993 # zt-tcp-proxy
  ];
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

  systemd.services.zt-tcp-proxy = {
    wantedBy = [ "multi-user.target" ];
    after = [ "zerotier-one.service" ];
    serviceConfig = {
      Type = "simple";
      # imap port
      ExecStart = "${pkgs.callPackage ../../pkgs/zerotier-tcp-proxy.nix {
        zerotierProxyPort = 993;
      }}/bin/zerotier-tcp-proxy";
      Restart = "always";
      RestartSec = 5;
      DynamicUser = true;
      User = "zt-tcp-proxy";
      Group = "zt-tcp-proxy";
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
    };
  };

  services.zerotierone = {
    enable = true;
    joinNetworks = [ "33d87fa6bd93423e" ];
  };
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "zerotierone" ];
}
