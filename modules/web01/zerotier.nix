{ config, lib, pkgs, ... }:
{
  networking.firewall.allowedTCPPorts = [ 9993 ];
  networking.firewall.allowedUDPPorts = [ 9993 ];
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
