{ pkgs, self, ... }: {
  security.acme.defaults.email = "admins@clan.lol";
  security.acme.acceptTerms = true;

  services.nginx = {
    virtualHosts."clan.lol" = {
      forceSSL = true;
      enableACME = true;
      root = self.inputs.homepage.packages.${pkgs.system}.default;
      extraConfig = ''
        charset utf-8;
        source_charset utf-8;
      '';
    };

    virtualHosts."www.clan.lol" = {
      forceSSL = true;
      enableACME = true;
      globalRedirect = "clan.lol";
    };
  };
}
