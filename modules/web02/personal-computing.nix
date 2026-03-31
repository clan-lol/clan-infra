{
  config,
  self,
  ...
}:
let
  localAddress = "10.0.0.2";
  hostAddress = "10.0.0.1";
  port = 3000;
  domain = "temp.${config.networking.fqdn}";
in
{
  imports = [ ../acme.nix ];

  containers.personal-computing = {
    autoStart = true;
    privateNetwork = true;
    inherit hostAddress localAddress;
    config = {
      imports = [ self.inputs.personal-computing.nixosModules.default ];

      services.personal-computing = {
        enable = true;
        package = self.inputs.personal-computing.packages.x86_64-linux.default;
        hostname = "0.0.0.0";
        inherit port;
      };

      networking.firewall.allowedTCPPorts = [ port ];

      system.stateVersion = "25.11";
    };
  };

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://${localAddress}:${toString port}";
      recommendedProxySettings = true;
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
