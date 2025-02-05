{ config, pkgs, ... }:
{
  boot.initrd.systemd.emergencyAccess =
    config.clan.core.vars.generators.emergency-access.files.password-hash.value;

  clan.core.vars.generators.emergency-password = {
    runtimeInputs = [
      pkgs.coreutils
      pkgs.mkpasswd
      pkgs.xkcdpass
    ];
    files.password.secret = true;
    files.password-hash.secret = false;

    script = ''
      xkcdpass --numwords 3 --delimiter - --count 1 | tr -d "\n" > $out/password
      mkpasswd -s -m sha-512 < $out/password | tr -d "\n" > $out/password-hash
    '';
  };
}
