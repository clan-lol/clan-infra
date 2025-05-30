{
  config,
  lib,
  ...
}:
{
  imports = [ ../acme.nix ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "outline"
    ];

  services.outline = {
    enable = true;

    publicUrl = "https://outline.${config.networking.fqdn}";
    storage.storageType = "local";
  };

  services.nginx.virtualHosts."outline.${config.networking.fqdn}" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://localhost:3000";
      recommendedProxySettings = true;
      proxyWebsockets = true;
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
