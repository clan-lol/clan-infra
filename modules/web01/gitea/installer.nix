{
  # http forward from https://clan.lol/sh to https://git.clan.lol/clan/clan-core/raw/branch/main/pkgs/gui-installer/gui-installer.sh
  services.nginx.virtualHosts."clan.lol" = {
    forceSSL = true;
    enableACME = true;
    locations."/install.sh".extraConfig = ''
      proxy_pass http://localhost:3002/clan/clan-core/raw/branch/main/pkgs/gui-installer/gui-installer.sh;
    '';
    locations."/install-dev.sh".extraConfig = ''
      proxy_pass http://localhost:3002/clan/clan-core/raw/branch/install-dev/pkgs/gui-installer/gui-installer.sh;
    '';
  };
}
