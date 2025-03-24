{ config, pkgs, ... }:
{
  services.harmonia.enable = true;
  # $ nix-store --generate-binary-cache-key cache.yourdomain.tld-1 harmonia.secret harmonia.pub
  services.harmonia.signKeyPaths = [ config.sops.secrets.harmonia-secret.path ];

  services.nginx = {
    package = pkgs.nginxStable.override { modules = [ pkgs.nginxModules.zstd ]; };
  };

  services.nginx.virtualHosts."cache.clan.lol" = {
    forceSSL = true;
    enableACME = true;
    locations."/".extraConfig = ''
      proxy_pass http://127.0.0.1:5000;
      proxy_set_header Host $host;
      proxy_redirect http:// https://;
      proxy_http_version 1.1;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $connection_upgrade;

      zstd on;
      zstd_types application/x-nix-archive;
    '';
  };
}
