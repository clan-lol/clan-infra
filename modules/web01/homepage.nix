{ pkgs, ...}: {
  security.acme.defaults.email = "admins@clan.lol";
  security.acme.acceptTerms = true;

  services.nginx = {
    virtualHosts."clan.lol" = {
      forceSSL = true;
      enableACME = true;
      root = pkgs.runCommand "clan.lol" {} ''
        mkdir -p $out;
        cat > $out/index.html <<EOF
        <html>
          <head>
            <title>Clan</title>
          </head>
          <body><h1>Clan</h1></body>
        </html>
        EOF
      '';
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
