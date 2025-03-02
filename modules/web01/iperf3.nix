{
  lib,
  config,
  pkgs,
  ...
}:
{

  config =
    let
      iperf3_authorized = config.clan.core.vars.generators.iperf3-password.files.authorized_users.path;
      iperf3_rsa = config.clan.core.vars.generators.iperf3-ca.files."private.pem".path;
      iperf3_home = "/var/run/iperf3";
    in
    {
      clan.core.vars.generators.iperf3-ca = {
        share = true;
        files."private.pem" = { };
        files."public.pem" = {
          deploy = false;
        };
        runtimeInputs = [
          pkgs.openssl
        ];
        script = ''
          set -epuo pipefail
          export PASSPHRASE="12345678"
          openssl genrsa -passout env:PASSPHRASE -des3 -out private.pem 2048
          openssl rsa -in private.pem -passin env:PASSPHRASE -outform PEM -pubout -out $out/public.pem
          openssl rsa -in private.pem -passin env:PASSPHRASE -out $out/private.pem -outform PEM
        '';
      };

      clan.core.vars.generators.iperf3-password = {

        runtimeInputs = [
          pkgs.coreutils
          pkgs.xkcdpass
          pkgs.gawk
        ];
        files.authorized_users = { };
        files.password = { };

        script = ''
          set -epuo pipefail
          xkcdpass --numwords 3 --delimiter - --count 1 | tr -d "\n" > $out/password
          S_USER=mario 
          S_PASSWD=$(cat $out/password)
          HASH=$(echo -n "{$S_USER}$S_PASSWD" | sha256sum | awk '{ print $1 }')
          echo "$S_USER,$HASH" > $out/authorized_users
        '';
      };

      networking.firewall.allowedUDPPorts = [ config.services.iperf3.port ];

      users.groups.iperf3 = { };
      users.users.iperf3 = {
        isSystemUser = true;
        group = "iperf3";
        createHome = true;
        home = iperf3_home;
      };

      systemd.services.iperf3 = {
        serviceConfig = {
          User = "iperf3";
          Group = "iperf3";
          DynamicUser = lib.mkForce false;
        };
        serviceConfig.ExecStartPre = lib.mkBefore [
          "+${pkgs.coreutils}/bin/install -o iperf3 -g iperf3 ${lib.escapeShellArg iperf3_authorized} ${iperf3_home}/authorized_users"

          "+${pkgs.coreutils}/bin/install -o iperf3 -g iperf3 ${lib.escapeShellArg iperf3_rsa} ${iperf3_home}/private.pem"
        ];
      };

      services.iperf3 = {
        enable = true;
        openFirewall = true;
        port = 5201;
        rsaPrivateKey = "${iperf3_home}/private.pem";
        authorizedUsersFile = "${iperf3_home}/authorized_users";
      };
    };
}
